# frozen_string_literal: true

require "mpv"
require "ap"

def test_instance
  MPV::Session.new(user_args: %w[--no-config])
end

class ProcSpy
  def initialize
    @mutex = Mutex.new
    @resource = ConditionVariable.new
    clear
  end

  def clear
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

  def wait(runs: 1, timeout: DEFAULT_TIMEOUT)
    start = Time.now
    @mutex.synchronize do
      loop do
        break if @queue.size >= runs
        break if (Time.now - start) >= timeout

        @resource.wait(@mutex, 0.05) # sleep 50ms and poll again
      end
    end
    result = @queue.dup
    clear
    result
  end
end
