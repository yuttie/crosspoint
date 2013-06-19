#!/usr/bin/ruby -Ku
# vim: set fileencoding=utf-8:

if RUBY_VERSION >= '1.9'
  Encoding.default_external = Encoding::UTF_8
end

require 'em-websocket'
require 'json'

NUM_GROUPS = 21
MSG_TYPE = 'comment'
post_num = 0


def mkdir_if_not_exist(dp)
  Dir.mkdir(dp,0757) unless Dir.exist?(dp)
  raise "Couldn't make a directory '#{dp}'." unless Dir.exist?(dp)
end

def read_file_if_exist(fp)
  File.exist?(fp) ? IO.read(fp) : ''
end

def escape(string)
  str = string ? string.dup : ""
  str.gsub!(/&/,  '&amp;')
  str.gsub!(/\"/, '&quot;')
  str.gsub!(/>/,  '&gt;')
  str.gsub!(/</,  '&lt;')
  str
end

def show_spaces(string)
  str = string ? string.dup : ""
  str.gsub!(/ /,  '&nbsp;')
  str.gsub!(/\n/, '<br>')
  str
end

#ipアドレスに対してグループidを割り振る
def check_group(ip_addr)
  gid = 0
  if File.exist?("./group_id/#{ip_addr}")
    gid = read_file_if_exist("./group_id/#{ip_addr}")
  else
    str_ip = ip_addr[ip_addr.size-2,ip_addr.size]
    gid = str_ip.to_i%NUM_GROUPS
    IO.write('./group_id/'   + ip_addr, gid)
  end
  return gid.to_i
end

def ip_zero(ip)
  IO.write('./group_id/' + ip, 0)
end

#投稿をファイルとして保存する処理
def message(msg,num)
  data = JSON.parse(msg)
  ip_addr = data['ip']
  content = show_spaces(escape(data['body']))
  #content = data['body']

  time = Time.now
  post_id = time.to_i.to_s + time.usec.to_s.rjust(6, '0')
  IO.write("./content/"   + post_id + "_" + num.to_i.to_s, content)
  IO.write('./ip_addr/'   + post_id, ip_addr)
  group_id = check_group(ip_addr)

  post_user = read_file_if_exist("./user_name/#{ip_addr}")
  if post_user == ""
    post_user = "NO NAME"
  end

  #JavaScriptに返す形式にmsgを整理
  new_msg = {'type'=>MSG_TYPE, 'post_num'=>num, 'post_user'=>post_user, 'body'=>content, 'time'=>time.strftime('%Y/%m/%d %H:%M:%S'),'ip_addr'=>ip_addr, 'gid'=>group_id}
  return JSON.generate(new_msg)
end

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

mkdir_if_not_exist('./content')
mkdir_if_not_exist('./ip_addr')
mkdir_if_not_exist('./group_id')
mkdir_if_not_exist('./user_name')
mkdir_if_not_exist('./user_id')

if Dir.exist?('./content')
  Dir.glob("./content/*") {|file|
    post_num = post_num + 1
  }
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
        #msgをを置き換える
        data = JSON.parse(msg)
        if(data['type'] == "comment")
          if(data['body'] == "円環の理")
            ip_zero(data['ip'])
          else
            post_num = post_num + 1
            nmsg = message(msg,post_num)
            ch.push(nmsg)
            $stderr.puts("#{sid}@#{ch_id} pushed a message '#{nmsg}'.")
          end
        else
          ch.push(msg)
          $stderr.puts("#{sid}@#{ch_id} pushed a message '#{msg}'.")
        end
      }

      ws.onclose {
        ch.unsubscribe(sid)
        $stderr.puts("#{sid} disconnected from #{ch_id}.")
      }
    }
  end
}