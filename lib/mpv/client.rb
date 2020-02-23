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

    # @param socket [Socket] the socket for communication with mpv
    def initialize(socket)
      @socket = socket
      @callbacks = []
      @replies = Queue.new
      @event_loop = Thread.new { loop { run_event_loop } }
    end

    # Sends a command to the mpv process.
    # @param args [Array] the individual command arguments to send
    # @return [Reply] mpv's response
    # @example
    #  client.command "loadfile", "mymovie.mp4", "append-play"
    def command(*args)
      payload = { "command" => args }
      @socket.puts(JSON.generate(payload))
      # this is kinda bad. in the future mpv might implement complete
      # asynchronous operation instead of blocking on the socket. for that
      # reason the code should be made more robust and send a request_id in
      # order to handle out of order replies
      @replies.pop
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

    private

    Reply = Struct.new(:data, :error, :request_id, keyword_init: true)
    Event = Struct.new(:name, :raw, keyword_init: true)

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
        @replies.push(Reply.new(response))
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
  end
end
