# frozen_string_literal: true

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

    # @return [Boolean] whether `mpv` is executable within the system path
    def self.available?
      Utils.which?("mpv")
    end

    # @return [Boolean] whether `mpv` supports the given flag
    # @note returns false if `mpv` is not available
    def self.flag?(flag)
      return false unless available?

      # MPV allows flags to be suffixed with =yes or =no, but doesn't
      # include these variations in their list. They also allow a --no-
      # prefix that isn't included in the list, so we normalize these out.
      # Additionally, we need to remove trailing arguments.
      normalized_flag = flag.sub(/^--no-/, "--").sub(/=\S*/, "")

      flags = `mpv --list-options`.split.select { |s| s.start_with?("--") }
      flags.include?(normalized_flag)
    end

    # Ensures that a binary named `mpv` can be executed.
    # @raise [MPVNotAvailableError] if no `mpv` executable in the system path
    def self.ensure_available!
      raise MPVNotAvailableError unless available?
    end

    # Ensures that that the `mpv` being executed supports the given flag.
    # @raise [MPVNotAvailableError] if no `mpv` executable in the system path
    # @raise [MPVUnsupportedFlagError] if `mpv` does not support the given flag
    def self.ensure_flag!(flag)
      ensure_available!
      raise MPVUnsupportedFlagError, flag unless flag?(flag)
    end

    # @param path [String] the path of the socket to be created
    #  (defaults to a tmpname in `/tmp`)
    # @param user_args [Array<String>] additional arguments to use when
    #  spawning mpv
    def initialize(path: Dir::Tmpname.make_tmpname("/tmp/mpv", ".sock"),
                   user_args: [])

      @socket_path = path
      @args = [
        "--idle",
        "--terminal=no",
        "--input-ipc-server=%<path>s" % { path: @socket_path },
      ].concat(user_args).uniq

      @args.each { |arg| self.class.ensure_flag! arg }

      @pid = Process.spawn("mpv", *@args)
    end

    # @return [Boolean] whether or not the mpv process is running
    def running?
      !!@pid && Process.waitpid(@pid, Process::WNOHANG).nil?
    rescue Errno::ECHILD
      false
    end
  end
end
