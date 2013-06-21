#!/usr/bin/ruby -Ku
# vim: set fileencoding=utf-8:

if RUBY_VERSION >= '1.9'
  Encoding.default_external = Encoding::UTF_8
end

require 'em-websocket'
require 'json'
require 'fileutils'

NUM_GROUPS = 21
MSG_TYPE = 'comment'
post_num = 0

def get_group_id()
  group_num_list = [3,6,9]

  # これまでのファイル数でグループを割り振る
  dir_path = "./group_id"
  file_num = file_count = File.exist?(dir_path) ? `ls #{dir_path}|wc -l`.to_i : 0

  # これまでのグループ数
  group_unit = 0
  group_num_list.each { |e| group_unit += e }
  group_num = ((file_num.to_f/group_unit.to_f).truncate * group_num_list.size)

  # modでグループを割り振る
  mod = (file_num % group_unit) + 1
  mod_group = 0
  max = 0
  group_num_list.each_with_index do |num,i|
    max += num
    if mod <= max
      mod_group = i + 1
      break
    end
  end

  group_id = group_num + mod_group
  return group_id
end

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

def get_number()
  time = Time.now
  serial_id = time.to_i.to_s + time.usec.to_s.rjust(6, '0')
  ### ここにグループIDを割り振り，group_idに保存する処理を入れる ###
  group_id = get_group_id()
  IO.write('./group_id/' + serial_id, group_id)
  return serial_id
end

#ipアドレスに対してグループidを割り振る
=begin
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
=end

def ip_zero(ip)
  IO.write('./group_id/' + ip, 0)
end

#ユーザのニックネーム・学生番号を登録する
def regist(data)
  if data['type'] == "user_name"
    IO.write("./user_name/" + data['id'], data['uname'])
  elsif data['type'] == "user_id"
    IO.write("./user_id/" + data['id'], data['uid'])
  end
end

def get_regist_data(id)
  uname = read_file_if_exist("./user_name/" + id)
  uid = read_file_if_exist("./user_id/" + id)
  if uname == ""
    uname = "NoName"
  end
  if uid == ""
    uid = "Unkown"
  end

  return JSON.generate({'type'=>'user_data', 'user_name'=>uname, 'user_id'=>uid})
end

#投稿をファイルとして保存する処理
def message(msg,num)
  data = JSON.parse(msg)
  unique_id = data['id']
  content = show_spaces(escape(data['body']))
  #content = data['body']

  time = Time.now
  post_id = time.to_i.to_s + time.usec.to_s.rjust(6, '0')
  IO.write("./content/"   + post_id + "_" + num.to_i.to_s, content)
  IO.write('./ip_addr/'   + post_id, unique_id)
  # group_id = check_group(ip_addr)
  group_id = read_file_if_exist("./group_id/#{unique_id}")

  post_user = read_file_if_exist("./user_name/#{unique_id}")
  if post_user == ""
    post_user = "NO NAME"
  end

  #JavaScriptに返す形式にmsgを整理
  new_msg = {'type'=>MSG_TYPE, 'post_num'=>num, 'post_user'=>post_user, 'body'=>content, 'time'=>time.strftime('%Y/%m/%d %H:%M:%S'),'ip_addr'=>unique_id, 'gid'=>group_id}
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

    unique_id = read_file_if_exist("./ip_addr/#{post_id}")
    content = show_spaces(escape(IO.read("./content/#{post_id}" + "_" + fp[1])))

    group_id = read_file_if_exist("./group_id/#{unique_id}")
    post_user = read_file_if_exist("./user_name/#{unique_id}")
    if post_user == ""
      post_user = "NO NAME"
    end

    log_messages.push(JSON.generate({'type'=>MSG_TYPE, 'post_num'=>fp[1], 'post_user'=>post_user,'body'=>content, 'time'=>time.strftime('%Y/%m/%d %H:%M:%S'),'ip_addr'=>unique_id, 'gid'=>group_id.to_i}))
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
        data = JSON.parse(msg)
        # cookieに登録するシリアルナンバーを送る
        if data['type'] == "cookie"
          if data['unique_id'] == "NoData"
            unique_id = get_number()
            cookie = JSON.generate({'type'=>'cookie', 'serial_num'=>unique_id})
            ws.send(cookie)
          else
            user_data = get_regist_data(data['unique_id'])
            ws.send(user_data)
          end
        # 投稿内容を整理し，保存・配信する
        elsif(data['type'] == "comment")
          if(data['body'] == "円環の理")
            ip_zero(data['ip'])
          else
            post_num = post_num + 1
            nmsg = message(msg,post_num)
            ch.push(nmsg)
            $stderr.puts("#{sid}@#{ch_id} pushed a message '#{nmsg}'.")
          end
        elsif data['type'] == 'user_name' || data['type'] == 'user_id'
          regist(data);
          user_data = get_regist_data(data['id'])
          ws.send(user_data)
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
