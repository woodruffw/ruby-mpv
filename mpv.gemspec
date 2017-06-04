# frozen_string_literal: true

require_relative "lib/mpv"

Gem::Specification.new do |s|
  s.name                  = "mpv"
  s.version               = MPV::VERSION
  s.summary               = "mpv - A ruby library for controlling mpv processes."
  s.description           = "A library for creating and controlling mpv instances."
  s.authors               = ["William Woodruff"]
  s.email                 = "william@tuffbizz.com"
  s.files                 = Dir["LICENSE", "*.md", ".yardopts", "lib/**/*"]
  s.required_ruby_version = ">= 2.3.0"
  s.homepage              = "https://github.com/woodruffw/ruby-mpv"
  s.license               = "MIT"
end
