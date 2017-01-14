module MPV
  # Encapsulates an object-method pair that will be invoked whenever
  # an {MPV::Client} receives an event.
  class Callback
    # @return [Object] the object that the callback will be issued to
    attr_accessor :object

    # @return [Symbol] the method that the callback will invoke
    attr_accessor :method

    # @param object [Object] the object that the callback will be issued to
    # @param method [Symbol] the method that the callback will invoke
    def initialize(object, method)
      @object = object
      @method = method
    end

    # Determines the validity of the instantiated callback. A callback
    # is said to be valid if the object responds to the given method
    # and the method has an arity of 1 (for the event data).
    # @return [Boolean] whether or not the callback is valid
    def valid?
      object.respond_to?(method) && object.method(method).arity == 1
    end

    # Dispatches the callback. Does nothing unless {#valid?} is true.
    # @param event [string] the event name
    # @return [void]
    def dispatch!(event)
      return unless valid?

      puts "dispatch #{event}"
      object.send method, event
    end
  end
end
