module MPV
  class MPVError < RuntimeError
  end

  class MPVNotAvailableError < MPVError
    def initialize
      super "Could not find an mpv binary to execute in the system path"
    end
  end

  class MPVUnsupportedFlagError < MPVError
    def initialize(flag)
      super "Installed mpv doesn't support the #{flag} flag"
    end
  end
end
