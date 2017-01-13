require "forwardable"

module MPV
  # Represents a combined mpv "server" and "client" communicating over
  # JSON IPC.
  class Session
    extend Forwardable

    # @return [String] the path of the socket being used for communication
    attr_reader :socket_path

    # @return [MPV::Server] the server object responsible for the mpv process
    attr_reader :server

    # @return [MPV::Client] the client communicating with mpv
    attr_reader :client

    # @param path [String] the path of the socket to create
    #  (defaults to a tmpname in `/tmp`)
    # @param user_args [Array<String>] additional arguments to use when
    #  spawning mpv
    def initialize(path: Dir::Tmpname.make_tmpname("/tmp/mpv", ".sock"),
                   user_args: [])
      @socket_path = path

      @server = Server.new(path: @socket_path, user_args: user_args)

      until File.exist?(@socket_path)
        sleep 0.1
      end

      @client = Client.new(@socket_path)
    end

    # @!method running?
    #  @return (see MPV::Server#running?)
    #  @see MPV::Server#running?
    def_delegators :@server, :running?

    # @!method callbacks
    #  @return (see MPV::Client#callbacks)
    #  @see MPV::Client#callbacks
    def_delegators :@client, :callbacks

    # @!method quit!
    #  @return (see MPV::Client#quit!)
    #  @see MPV::Client#quit!
    def_delegators :@client, :quit!
  end
end
