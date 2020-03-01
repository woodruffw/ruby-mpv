# frozen_string_literal: true

require "socket"
require "json"

module MPV
  # Represents a connection to a mpv process that has been spawned
  # with an IPC socket.
  # @see https://mpv.io/manual/stable/#json-ipc
  #  MPV's IPC docs
  # @see https://mpv.io/manual/master/#properties
  #  MPV's property docs
  class Client
    # @return [Array<Proc>] callback procs that will be invoked
    #  whenever mpv emits an event
    attr_accessor :callbacks

    # @param path [String] path to the unix socket
    # @return [Client] an instance of this class
    def self.from_unix_socket_path(path)
      new(UNIXSocket.new(path))
    end

    # @param file_descriptor [Integer] file descriptor id
    # @return [Client] an instance of this class
    def self.from_file_descriptor(file_descriptor)
      new(Socket.for_fd(file_descriptor))
    end

    # @return [Client] an instance of this class using fd from --mpv-ipc-fd
    def self.script
      require "optparse"
      parser = OptionParser.new do |opts|
        opts.on("--mpv-ipc-fd=N", Integer) do |value|
          return from_file_descriptor(value)
        end
      end
      parser.parse!
      raise ArgumentError, "--mpv-ipc-fd argument not provided"
    end

    # @param socket [Socket] the socket for communication with mpv
    def initialize(socket)
      @socket = socket
      @callbacks = [
        method(:observer_callback),
        method(:client_message_callback),
      ]
      @replies = MultiQueue.new
      @id = Concurrent::AtomicFixnum.new
      @observers = Concurrent::Hash.new
      @messages = Concurrent::Hash.new
      @event_loop = Thread.new { loop { run_event_loop } }
    end

    # Don't use 0, mpv observers don't work otherwise, it's treatead as nil
    MIN_ID = 1

    # The virtual machines's maximum Fixnum. Equals to 2^62 on cruby compiled
    # on a 64bit machine, 2^64 at most on better VMs like jruby. mpv goes up
    # to 2^64 so this is a safe value to make the atomic counter roll-over
    MAX_ID = (2**(0.size * 8 - 2) - 1)

    def next_id
      @id.update do |current|
        new = current + 1
        new >= MAX_ID ? MIN_ID : new
      end
    end

    # Sends a command to the mpv process.
    # @param args [Array] the individual command arguments to send
    # @return [Reply] mpv's response
    # @example
    #  client.command "loadfile", "mymovie.mp4", "append-play"
    def command(*args)
      request_id = next_id
      payload = { "command" => args, "request_id" => request_id }
      @socket.puts(JSON.generate(payload))
      @replies.pop(request_id)
    end

    # Sends a property change to the mpv process.
    # @param property_name [String] the property name (e.g.: volume)
    # @param value [Object] the new property value
    # @return [Reply] mpv's response
    # @example
    #  client.set_property "pause", true
    def set_property(property_name, value)
      command("set_property", property_name, value)
    end

    # Retrieves a property from the mpv process.
    # @param property_name [String] the property name (e.g.: volume)
    # @return [Reply] mpv's response
    # @example
    #  client.get_property "pause" # => true
    #  client.get_property "volume" # => 100.0
    def get_property(property_name)
      command("get_property", property_name)
    end

    # Observes property changes
    # @param property [String] the property to observe
    # @yield [ObserverEvent] event triggered by a property change
    # @return [Integer] the observer id to use with unobserve_property
    # @example
    #  client.observe_property("volume") do |event|
    #   puts "the new volume is #{event.data}"
    #  end
    def observe_property(property, &block)
      observer_id = next_id
      @observers[observer_id] = block
      command("observe_property", observer_id, property)
      observer_id
    end

    # Unobserves property changes
    # @param observer_id [Integer] the return value of #observe_property
    # @return [Integer] the observer id to use with unobserve_property
    # @return [void]
    def unobserve_property(observer_id)
      mpv.command("unobserve_property", observer_id)
    end

    # Registers a client-message handler
    # @param message [String] the script-message identifier
    # @yield [Array] called with the arguments passed to client-message
    # @return [void]
    # @example
    #  client.register_message_handler("cool-message") do |a, b|
    #    puts "hello #{a}-#{b}" # => hello, mikuru-chan
    #  end
    #
    #  client.command("script-message", "cool-message", "mikuru", "chan")
    def register_message_handler(message, &block)
      @messages[message] = block
    end

    # Unregisters a client-message handler
    # @param message [String] the client-message identifier
    # @return [void]
    def unregister_message_handler(message)
      @messages.delete(message)
    end

    # Registers a keybinding section
    # @param keys [Array<String>] the keys to bind (in input.conf format)
    # @param section [String] optional section name
    # @param flags [String] either "default", or "force" (default: force)
    # @yield [KeyEvent] the keybinding event
    # @return [String] section name (for unregister_keybindings)
    # @example
    #  client.register_keybindings(%w[a b]) do |event|
    #    event.keydown? # => true
    #    event.key # => "b"
    #  end
    #
    #  client.command("keypress", "b")
    def register_keybindings(keys, section: nil, flags: "default", &block)
      section ||= ("a".."z").to_a.sample(8).join
      namespaced_section = [client_name, section].join("/")
      register_message_handler(section, &block)
      contents = keys.map { |k| "#{k} script-binding #{namespaced_section}" }
      command("define-section", section, contents.join("\n"), flags)
      command("enable-section", section)
      section
    end

    # Unregisters a keybinding section
    # @param section [String] section name
    # @param flags [String] either "default", or "force" (default: force)
    # @return [void]
    def unregister_keybindings(section)
      command("disable-section", section)
      command("define-section", section, "")
      unregister_message_handler(section)
    end

    # Blocks the main thread until the mpv process exits
    # @return [void]
    def join
      require "thwait"
      ThreadsWait.new(@event_loop).join
    end

    private

    Reply = Struct.new(:data, :error, :request_id, keyword_init: true)
    Event = Struct.new(:name, :raw, keyword_init: true)
    ObserverEvent = Struct.new(:name, :data, :raw, keyword_init: true)

    # mpv command reply
    class Reply
      def success?
        error == "success"
      end

      def error?
        !success
      end
    end

    def run_event_loop
      response = JSON.parse(@socket.readline)
      if response["event"]
        event = Event.new(name: response["event"], raw: response)
        run_callbacks(event)
      else
        reply = Reply.new(response)
        @replies.push(reply.request_id, reply)
      end
    rescue StandardError
      Thread.exit
    end

    def run_callbacks(event)
      callbacks.each do |callback|
        Thread.new do
          callback.call(event)
        end
      end
    end

    def observer_callback(event)
      return unless event.name == "property-change"

      id = event.raw.dig("id")
      e = ObserverEvent.new(
        name: event.name,
        raw: event.raw,
        data: event.raw["data"]
      )
      @observers.fetch(id).call(e)
    end

    KeyEvent = Struct.new(:section, :state, :key, :key2)

    class KeyEvent
      def keydown?
        state == "d-"
      end

      def keyup?
        state == "u-"
      end
    end

    def client_name
      @client_name ||= command("client_name").data
    end

    def client_message_callback(event)
      return unless event.name == "client-message"

      message, *args = event.raw.fetch("args")
      message, *args = [args.first, KeyEvent.new(*args)] if message == "key-binding"

      @messages.fetch(message, nil)&.call(*args)
    end
  end
end
