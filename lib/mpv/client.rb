require "socket"
require "json"
require "thread"

module MPV
  # Represents a connection to a mpv process that has been spawned
  # with an IPC socket.
  # @see https://mpv.io/manual/stable/#json-ipc
  #  MPV's IPC docs
  # @see https://mpv.io/manual/master/#properties
  #  MPV's property docs
  class Client
    # @return [String] the path of the socket used to communicate with mpv
    attr_reader :socket_path

    # @return [Array<Object>] objects whose #event method will be called
    #  whenever mpv emits an event
    attr_accessor :callbacks

    # @param path [String] the domain socket for communication with mpv
    def initialize(path)
      @socket_path = path

      @socket = UNIXSocket.new(@socket_path)

      @callbacks = []

      @command_queue = Queue.new
      @result_queue = Queue.new
      @event_queue = Queue.new

      @command_thread = Thread.new { pump_commands! }
      @results_thread = Thread.new { pump_results! }
      @events_thread = Thread.new { dispatch_events! }
    end

    # Sends a command to the mpv process.
    # @param args [Array] the individual command arguments to send
    # @return [Hash] mpv's response to the command
    # @example
    #  client.command "loadfile", "mymovie.mp4", "append-play"
    def command(*args)
      payload = {
        "command" => args
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
      command "set_property", *args
    end

    # Retrieves a property from the mpv process.
    # @param args [Array] the individual property arguments to send
    # @return [Object] the value of the property
    # @example
    #  client.get_property "pause" # => true
    def get_property(*args)
      command("get_property", *args)["data"]
    end

    # Terminates the mpv process.
    # @return [void]
    # @note this object becomes garbage once this method is run
    def quit!
      command "quit"
      @socket = nil
      File.delete(@socket_path) if File.exist?(@socket_path)
    end

    private

    def pump_commands!
      loop do
        begin
          @socket.puts(@command_queue.pop)
        rescue # the player is deactivating
          Thread.exit
        end
      end
    end

    def pump_results!
      loop do
        begin
          response = JSON.parse(@socket.readline)

          if response["event"]
            @event_queue << response["event"]
          else
            @result_queue << response
          end
        rescue # the player is deactivating
          Thread.exit
        end
      end
    end

    def dispatch_events!
      loop do
        event = @event_queue.pop

        callbacks.each do |callback|
          Thread.new do
            callback.send :event, event if callback.respond_to?(:event)
          end
        end
      end
    end
  end
end
