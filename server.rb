#!/usr/bin/ruby -Ku
# vim: set fileencoding=utf-8:
# new
if RUBY_VERSION >= '1.9'
  Encoding.default_external = Encoding::UTF_8
end

require 'em-websocket'

#所見ユーザに過去の投稿を全て送信するために準備
def log_messages()
  log_messages = Array.new
  #保存されたメッセージの取得
  Dir.glob('./content/*').sort.each_with_index {|prefp, i|
    fp = prefp.split("_")

    time = Time.now
    post_id = File.basename(fp[0])
    time = Time.at(post_id[0...-6].to_i, post_id[-6..-1].to_i)

    ip_addr = read_file_if_exist("./ip_addr/#{post_id}")
    content = show_spaces(escape(IO.read("./content/#{post_id}" + "_" + fp[1])))
    if ip_addr.empty? || ip_addr == ""
      next
    end
    group_id = read_file_if_exist("./group_id/#{ip_addr}")
    post_user = read_file_if_exist("./user_name/#{ip_addr}")
    if post_user == ""
      post_user = "NO NAME"
    end

    log_messages.push(JSON.generate({'type'=>MSG_TYPE, 'post_num'=>fp[1], 'post_user'=>post_user,'body'=>content, 'time'=>time.strftime('%Y/%m/%d %H:%M:%S'),'ip_addr'=>ip_addr, 'gid'=>group_id.to_i}))
  }
  return log_messages
end

EventMachine.run {
  @channels = {}

  EventMachine::WebSocket.start(host: ARGV[1] || "0.0.0.0", port: (ARGV[0] || 9090).to_i) do |ws|
    ws.onopen {|handshake|
      ch_id = handshake.path
      @channels[ch_id] ||= EventMachine::Channel.new
      ch = @channels[ch_id]

      #接続が区立されたユーザ１人に対して既存メッセージを送信する
      log_msg = log_messages()
      log_msg.each {|msg|
        ws.send(msg)
      }

      sid = ch.subscribe {|msg|
        ws.send(msg)
      }
      $stderr.puts("#{sid} connected to #{ch_id}.")

      ws.onmessage {|msg|
        ch.push(msg)
        $stderr.puts("#{sid}@#{ch_id} pushed a message '#{msg}'.")
      }

      ws.onclose {
        ch.unsubscribe(sid)
        $stderr.puts("#{sid} disconnected from #{ch_id}.")
      }
    }
  end
}
