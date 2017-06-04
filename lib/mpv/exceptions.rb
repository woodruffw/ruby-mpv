# frozen_string_literal: true

module MPV
  # A generic error class for ruby-mpv.
  class MPVError < RuntimeError
  end

  # Raised when `mpv` cannot be executed.
  class MPVNotAvailableError < MPVError
    def initialize
      super "Could not find an mpv binary to execute in the system path"
    end
  end

  # Raised when `mpv` doesn't support a requested flag.
  class MPVUnsupportedFlagError < MPVError
    def initialize(flag)
      super "Installed mpv doesn't support the #{flag} flag"
    end
  end
end
