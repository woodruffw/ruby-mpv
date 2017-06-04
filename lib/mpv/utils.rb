# frozen_string_literal: true

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
  end
end
