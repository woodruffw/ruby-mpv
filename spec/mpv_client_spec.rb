# frozen_string_literal: true

require "spec_helper"

describe MPV::Client do
  before(:each) do
    @session = test_instance
    @mpv = @session.client
  end

  after(:each) do
    @mpv.command("quit")
  end

  it "can query properties" do
    result = @mpv.get_property("volume")
    expect(result).to be_success
    expect(result.data).to eql(100.0)
  end

  it "can set properties" do
    result = @mpv.get_property("volume")
    expect(result).to be_success
    expect(result.data).to eql(100.0)

    result = @mpv.set_property("volume", 50)
    expect(result).to be_success

    result = @mpv.get_property("volume")
    expect(result).to be_success
    expect(result.data).to eql(50.0)
  end

  it "can observe properties" do
    spy = ProcSpy.new
    @mpv.observe_property(:volume, &spy)
    @mpv.set_property(:volume, 10)
    result = spy.wait(runs: 2)
    expect(result.map(&:first).map(&:data)).to eql([100.0, 10.0])
  end
end
