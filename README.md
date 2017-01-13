ruby-mpv
========

[![Gem Version](https://badge.fury.io/rb/mpv.svg)](https://badge.fury.io/rb/mpv)

A ruby library for controlling mpv processes.

### Installation

```bash
$ gem install mpv
```

### Example

For full documentation, please see the
[RubyDocs](http://www.rubydoc.info/gems/mpv/).

```ruby
# this will be called every time mpv sends an event back over the socket
def event(event)
  puts "look ma! a callback: #{event}"
end

session = MPV::Session.new # contains both a MPV::Server and a MPV::Client
session.client.callbacks << self
session.client.get_property "pause"
session.client.command "get_version"
session.client.command "loadlist", "my_huge_playlist.txt", "append"
session.client.quit!
```
