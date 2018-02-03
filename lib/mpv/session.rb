# frozen_string_literal: true

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
    def initialize(path: File.join('/tmp', Utils.tmpname), user_args: [])
      @socket_path = path

      @server = Server.new(path: @socket_path, user_args: user_args)

      sleep 0.1 until File.exist?(@socket_path)

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

    # @!method command
    #  @return (see MPV::Client#command)
    #  @see MPV::Client#command
    def_delegators :@client, :command

    # @!method get_property
    #  @return (see MPV::Client#get_property)
    #  @see MPV::Client#get_property
    def_delegators :@client, :get_property

    # @!method set_property
    #  @return (see MPV::Client#set_property)
    #  @see MPV::Client#set_property
    def_delegators :@client, :set_property
  end
end
