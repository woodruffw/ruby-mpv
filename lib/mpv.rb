require_relative "mpv/exceptions"
require_relative "mpv/utils"
require_relative "mpv/callback"
require_relative "mpv/client"
require_relative "mpv/server"
require_relative "mpv/session"

# The toplevel namespace for ruby-mpv.
module MPV
  # The current version of ruby-mpv.
  VERSION = "1.1.2".freeze
end
