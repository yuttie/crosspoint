#!/usr/bin/ruby -Ku
# vim: set fileencoding=utf-8:

if RUBY_VERSION >= '1.9'
  Encoding.default_external = Encoding::UTF_8
end

require 'em-websocket'
require 'thread'

ts = []
EventMachine::WebSocket.start(host: "0.0.0.0", port: 8888) do |ws|
  thread = nil
  ws.onmessage {|msg|
    ts.each {|t| t[:queue].push(msg) }
    p msg
  }
  ws.onopen {
    thread = Thread.new {
      this = Thread.current
      this[:queue] = Queue.new
      while true
        msg = this[:queue].pop
        if (msg == "end")
          break
        else
          ws.send(msg)
        end
      end
    }
    ts << thread
    p ts
  }
  ws.onclose {
    ts.delete(thread)
    p ts
  }
end
