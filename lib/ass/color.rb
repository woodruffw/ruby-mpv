# frozen_string_literal: true

module Ass
  # Represents a SubStationAlpha Color
  class Color
    {
      black: [0, 0, 0],
      white: [255, 255, 255],
      red: [255, 0, 0],
      green: [0, 255, 0],
      yellow: [0, 255, 255],
    }.each do |k, v|
      define_singleton_method(k) { new(*v) }
    end

    # @param red [Integer] 0 to 255
    # @param green [Integer] 0 to 255
    # @param blue [Integer] 0 to 255
    def initialize(red, green, blue)
      @rgb = [red, green, blue]
    end

    # @return [String] ASS script representation
    def to_script
      s = @rgb.map(&method(:to_hex)).join("")
      "&H#{s}&"
    end

    private

    def to_hex(component)
      component.to_s(16).upcase.rjust(2, "0")
    end
  end
end
