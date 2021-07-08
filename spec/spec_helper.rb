# frozen_string_literal: true

require "mpv"
require "ap"

def test_instance
  MPV::Session.new(user_args: %w[--no-config])
end
