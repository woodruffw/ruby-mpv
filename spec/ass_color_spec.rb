# frozen_string_literal: true

require "spec_helper"

describe Ass::Color do
  it "converts white" do
    expect(Ass::Color.white.to_script).to eql("&HFFFFFF&")
  end
end
