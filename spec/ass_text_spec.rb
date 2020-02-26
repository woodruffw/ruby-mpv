# frozen_string_literal: true

require "spec_helper"

describe Ass::Text do
  it "deals with styled text" do
    colors = Ass::Color
    s = Ass::Text.new("適当")
    s = s.border(1, colors.black).color(colors.white).font_size(40)
    expect(s.to_script).to eql("{\\bord1}{\\3c&H000000&}{\\1c&HFFFFFF&}{\\fs40}適当")
  end
end
