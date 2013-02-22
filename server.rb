#!/usr/bin/ruby -Ku
# vim: set fileencoding=utf-8:

if RUBY_VERSION >= '1.9'
  Encoding.default_external = Encoding::UTF_8
end

require 'em-websocket'

EventMachine.run {
  @channel = EventMachine::Channel.new

  EventMachine::WebSocket.start(host: "0.0.0.0", port: 8888) do |ws|
    ws.onopen {
      sid = @channel.subscribe {|msg|
        ws.send(msg)
      }
      ws.onmessage {|msg|
        @channel.push(msg)
        p msg
      }
      ws.onclose {
        @channel.unsubscribe(sid)
      }
    }
  end
}
