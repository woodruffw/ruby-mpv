# frozen_string_literal: true

module MPV
  # Atomic Int64 counter to generate request_ids for mpv
  class AtomicInt64
    MAX_INT64 = 9_223_372_036_854_775_807

    def initialize(start = 0)
      @value = start
      @start = start
      @mutex = Mutex.new
    end

    def incr(amount = 1)
      @mutex.synchronize do
        @value += amount
        @value = @start if @value >= MAX_INT64
        @value
      end
    end
  end
end
