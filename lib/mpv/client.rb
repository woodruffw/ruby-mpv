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
    # @return Client
    def self.from_unix_socket_path(path)
      new(UNIXSocket.new(path))
    end

    # @param file_descriptor [Integer] file descriptor id
    # @return Client
    def self.from_file_descriptor(file_descriptor)
      new(Socket.for_fd(file_descriptor))
    end

    # @param socket [Socket] the socket for communication with mpv
    def initialize(socket)
      @socket = socket
      @alive = true

      @callbacks = []

      @command_queue = Queue.new
      @result_queue = Queue.new
      @event_queue = Queue.new

      @command_thread = Thread.new { pump_commands! }
      @results_thread = Thread.new { pump_results! }
      @events_thread = Thread.new { dispatch_events! }
    end

    # @return [Boolean] whether or not the player is currently active
    # @note When false, most methods will cease to function.
    def alive?
      @alive
    end

    # Sends a command to the mpv process.
    # @param args [Array] the individual command arguments to send
    # @return [Hash] mpv's response to the command
    # @example
    #  client.command "loadfile", "mymovie.mp4", "append-play"
    def command(*args)
      return unless alive?

      payload = {
        "command" => args,
      }

      @command_queue << JSON.generate(payload)

      @result_queue.pop
    end

    # Sends a property change to the mpv process.
    # @param args [Array] the individual property arguments to send
    # @return [Hash] mpv's response
    # @example
    #  client.set_property "pause", true
    def set_property(*args)
      return unless alive?

      command "set_property", *args
    end

    # Retrieves a property from the mpv process.
    # @param args [Array] the individual property arguments to send
    # @return [Object] the value of the property
    # @example
    #  client.get_property "pause" # => true
    def get_property(*args)
      return unless alive?

      command("get_property", *args)["data"]
    end

    # Terminates the mpv process.
    # @return [void]
    # @note this object becomes garbage once this method is run
    def quit!
      command "quit" if alive?
    ensure
      @alive = false
      @socket = nil
    end

    private

    # Pumps commands from the command queue to the socket.
    # @api private
    def pump_commands!
      loop do
        begin
          @socket.puts(@command_queue.pop)
        rescue StandardError # the player is deactivating
          @alive = false
          Thread.exit
        end
      end
    end

    # Distributes results in a nonterminating loop.
    # @api private
    def pump_results!
      loop do
        distribute_results!
      end
    end

    # Distributes results to the event and result queues.
    # @api private
    def distribute_results!
      response = JSON.parse(@socket.readline)

      if response["event"]
        @event_queue << response
      else
        @result_queue << response
      end
    rescue StandardError
      @alive = false
      Thread.exit
    end

    # Takes events from the event queue and dispatches them to callbacks.
    # @api private
    def dispatch_events!
      loop do
        event = @event_queue.pop

        callbacks.each do |callback|
          Thread.new do
            callback.call event
          end
        end
      end
    end
  end
end
