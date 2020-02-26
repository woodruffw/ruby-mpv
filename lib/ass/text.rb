# frozen_string_literal: true

module Ass
  # Represents a SubStationAlpha styled String
  class Text
    def initialize(text)
      @text = text
      @style = {}
    end

    # @param size [Integer]
    # @return [Text]
    def font_size(size)
      @style.merge!(fs: size)
      self
    end

    # @param size [Integer]
    # @param color [Color]
    # @return [Text]
    def border(size, color)
      @style.merge!(bord: size, "3c": color.to_script)
      self
    end

    # @param color [Color]
    # @return [Text]
    def color(color)
      @style.merge!("1c": color.to_script)
      self
    end

    # @return [String] ASS script representation
    def to_script
      [@style.map { |k, v| "{\\#{k}#{v}}" }.join, @text].join
    end
  end
end
