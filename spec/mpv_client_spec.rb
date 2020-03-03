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
    fence = MPV::Fence.new
    @mpv.observe_property(:volume, &fence)
    @mpv.set_property(:volume, 10)
    result = fence.wait(runs: 2)
    expect(result.map(&:first).map(&:data)).to eql([100.0, 10.0])
  end

  it "can handle client-message" do
    fence = MPV::Fence.new
    m = "cool-message"
    @mpv.register_message_handler(m, &fence)
    @mpv.command("script-message", m, "a", "b")
    @mpv.command("script-message", m, "c", "d")
    result = fence.wait(runs: 2)
    expect(result).to eql([%w[a b], %w[c d]])
  end

  it "can register a binding" do
    fence = MPV::Fence.new
    section = @mpv.register_keybindings(%w[b c d], &fence)
    @mpv.command("keypress", "g")
    @mpv.command("keypress", "c")
    expect(fence.wait.map(&:first).map(&:key)).to eql(%w[c])

    @mpv.unregister_keybindings(section)
    @mpv.command("keypress", "b")
    expect(fence.wait(timeout: 0.5).size).to eql(0)
  end

  it "can connect through inherited file descriptor" do
    script = File.expand_path("fd_test.run", __dir__)
    command = [
      "mpv",
      "--no-config",
      "--idle",
      "--really-quiet",
      "--script=#{script}",
    ].join(" ")
    expect(`#{command}`.strip).to eql("100.0")
  end

  it "doesn't deadlock" do
    fence = MPV::Fence.new
    section = @mpv.register_keybindings(%w[b]) do
      volume = @mpv.get_property("volume").data
      fence.to_proc.call(volume)
    end
    @mpv.command("keypress", "b")
    expect(fence.wait).to eql([[100.0]])
    @mpv.unregister_keybindings(section)
  end

  it "handles messages correctly" do
    id1 = @mpv.create_osd_message("foo")
    id2 = @mpv.create_osd_message("bar")
    id3 = @mpv.create_osd_message("baz")
    expect(@mpv.osd_messages.values.map(&:text)).to eql(%w[foo bar baz])
    @mpv.edit_osd_message(id2, "pasta")
    expect(@mpv.osd_messages.values.map(&:text)).to eql(%w[foo pasta baz])
    @mpv.delete_osd_message(id1)
    @mpv.delete_osd_message(id3)
    expect(@mpv.osd_messages.values.map(&:text)).to eql(%w[pasta])
    @mpv.clear_osd_messages
    expect(@mpv.osd_messages.size).to eql(0)
  end

  it "handles messages with a timeout" do
    @mpv.create_osd_message("foo", timeout: 0.2)
    expect(@mpv.osd_messages.values.map(&:text)).to eql(%w[foo])
    sleep(0.3)
    expect(@mpv.osd_messages.size).to eql(0)
  end

  it "handles modal keypresses" do
    fence = MPV::Fence.new
    @mpv.enter_modal_mode("really delete?", %w[y n], &fence)
    expect(@mpv.osd_messages.size).to eql(1)
    @mpv.command("keypress", "y")
    expect(fence.wait.map(&:first).map(&:key)).to eql(["y"])
    expect(@mpv.osd_messages.size).to eql(0)
  end

  it "handles modal exit key" do
    fence = MPV::Fence.new
    @mpv.enter_modal_mode("really delete?", %w[y n], &fence)
    expect(@mpv.osd_messages.size).to eql(1)
    @mpv.command("keypress", "ESC")
    expect(fence.wait(timeout: 0.5).map(&:first).map(&:key)).to eql([])
    expect(@mpv.osd_messages.size).to eql(0)
  end
end
