# frozen_string_literal: true

module MPV
  # Holds state to handle request/response lifecycle for mpv's ipc protocol
  class MultiQueue
    def initialize
      @queues = Hash.new { |hash, key| hash[key] = Queue.new }
      @mutex = Mutex.new
    end

    # Pushes a value a for a certain request_id
    # @param id [Integer] the request_id
    # @param value [Object]
    # @return [void] mpv's response
    def push(id, value)
      queue_for(id).push(value)
    end

    # Pops a value a for a certain request_id
    # @param id [Integer] the request_id
    # @return [Object] popped value
    def pop(id)
      result = queue_for(id).pop
      clear_queue_for(id)
      result
    end

    private

    def queue_for(id)
      @mutex.synchronize { @queues[id] }
    end

    def clear_queue_for(id)
      @mutex.synchronize { @queues.delete(id) }
    end
  end
end
