# frozen_string_literal: true

module MPV
  # Utility class to test threaded asyncronous code that calls blocks/procs.
  # Exposed as production code for the sake of the users who want to TDD their
  # mpv Ruby scripts (since it's not trivial code to write).
  class Fence
    def initialize
      @mutex = Mutex.new
      @resource = ConditionVariable.new
      @queue = []
    end

    def to_proc
      proc do |*args|
        @mutex.synchronize do
          @queue << args.dup
          @resource.signal
        end
      end
    end

    DEFAULT_TIMEOUT = 5

    # Waits until the spy has been run at least "runs" times or the timeout is
    # triggered, and returns the calls performed on the spy
    # @return [Array<Array<Object>>] array of calls to the spy, containing
    #  arguments of each call
    def wait(runs: 1, timeout: DEFAULT_TIMEOUT)
      start = Concurrent.monotonic_time
      @mutex.synchronize do
        loop do
          break if @queue.size >= runs
          break if (Concurrent.monotonic_time - start) >= timeout

          @resource.wait(@mutex, 0.05) # sleep 50ms and poll again
        end
        result = @queue.dup
        @queue.clear
        result
      end
    end

    # Clears the calls history
    def clear!
      @mutex.synchronize do
        @queue.clear
      end
    end
  end
end
