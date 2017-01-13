require "tempfile"

module MPV
  # Represents an active mpv process.
  class Server
    # @return [Array<String>] the command-line arguments used when spawning mpv
    attr_reader :args

    # @return [String] the path to the socket used by this mpv process
    attr_reader :socket_path

    # @return [Fixnum] the process id of the mpv process
    attr_reader :pid

    # @param path [String] the path of the socket to be created
    #  (defaults to a tmpname in `/tmp`)
    # @param user_args [Array<String>] additional arguments to use when
    #  spawning mpv
    def initialize(path: Dir::Tmpname.make_tmpname("/tmp/mpv", ".sock"),
                   user_args: [])
      @socket_path = path
      @args = [
        "--idle",
        "--no-terminal",
        "--input-ipc-server=%{path}" % { path: @socket_path },
      ] + user_args

      @pid = Process.spawn("mpv", *@args)
    end

    # @return [Boolean] Whether or not the current instance is running.
    def running?
      begin
        !!@pid && Process.waitpid(@pid, Process::WNOHANG).nil?
      rescue Errno::ECHILD
        false
      end
    end
  end
end
