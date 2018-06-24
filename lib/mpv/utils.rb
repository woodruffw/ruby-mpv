# frozen_string_literal: true

require "English"

module MPV
  # Various utility methods for ruby-mpv.
  module Utils
    # Tests whether the given utility is available in the system path.
    # @param util [String] the utility to test
    # @return [Boolean] whether or not the utility is available
    # @api private
    def self.which?(util)
      ENV["PATH"].split(File::PATH_SEPARATOR).any? do |path|
        File.executable?(File.join(path, util))
      end
    end

    def self.tmpsock
      t = Time.now.strftime("%Y%m%d")
      "mpv#{t}-#{$PROCESS_ID}-#{rand(0x100000000).to_s(36)}.sock"
    end
  end
end
