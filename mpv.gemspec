# frozen_string_literal: true

require_relative "lib/mpv/version"

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
  s.add_dependency "concurrent-ruby", "~> 1.1.6"
  s.add_dependency "e2mmap"
  s.add_dependency "thwait"
  s.add_development_dependency "awesome_print"
  s.add_development_dependency "bundler"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "redcarpet"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rubocop", "~> 0.79.0"
  s.add_development_dependency "yard", "~> 0.9"
end
