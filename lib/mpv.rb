# frozen_string_literal: true

require "concurrent"
require_relative "mpv/version"

module MPV
end

require_relative "ass/color"
require_relative "ass/text"

require_relative "mpv/exceptions"
require_relative "mpv/multi_queue"
require_relative "mpv/utils"
require_relative "mpv/client"
require_relative "mpv/server"
require_relative "mpv/session"
