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

# グループの振り分け
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

def get_number()
  time = Time.now
  serial_id = time.to_i.to_s + time.usec.to_s.rjust(6, '0')
  ### ここにグループIDを割り振り，group_idに保存する処理を入れる ###
  group_id = get_group_id()
  IO.write('./group_id/' + serial_id, group_id)
  return serial_id
end

def get_number()
  time = Time.now
  serial_id = time.to_i.to_s + time.usec.to_s.rjust(6, '0')
  ### ここにグループIDを割り振り，group_idに保存する処理を入れる ###
  group_id = get_group_id()
  IO.write('./group_id/' + serial_id, group_id)
  return serial_id
end

def process_ta()
  time = Time.now
  serial_id = time.to_i.to_s + time.usec.to_s.rjust(6, '0')
  ### ここにグループIDを割り振り，group_idに保存する処理を入れる ###
  IO.write('./group_id/' + serial_id, "0")
  return serial_id
end

#TA投稿用
def ip_zero(msg)
  data = JSON.parse(msg)
  unique_id = data['id']
  #あえてエスケープをかけない. HTMLタグを使用可に.
  content = show_spaces(data['body'])
  #content = data['body']

  time = Time.now
  post_id = time.to_i.to_s + time.usec.to_s.rjust(6, '0')
  IO.write("./content/"   + post_id + "_TA", content)
  IO.write('./ip_addr/'   + post_id, unique_id)
  group_id = read_file_if_exist("./group_id/#{unique_id}")

  post_user = read_file_if_exist("./user_name/#{unique_id}")

  #JavaScriptに返す形式にmsgを整理
  new_msg = {'type'=>'only_TA', 'post_num'=>'TA', 'post_user'=>post_user, 'body'=>content, 'time'=>time.strftime('%Y/%m/%d %H:%M:%S'),'ip_addr'=>unique_id, 'gid'=>group_id}
  return JSON.generate(new_msg)
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
def store_post(post, num)
  user_id = post['id']
  content = post['body']

  time = Time.now
  post_id = time.to_i.to_s + time.usec.to_s.rjust(6, '0')
  IO.write('./content/' + post_id + '_' + num.to_i.to_s, content)
  IO.write('./post_num/' + post_id, num)
  IO.write('./ip_addr/' + post_id, user_id)
  post_id
end

def load_post(post_id)
  time = Time.at(post_id[0...-6].to_i, post_id[-6..-1].to_i)
  post_num = read_file_if_exist("./post_num/#{post_id}")
  content  = read_file_if_exist("./content/#{post_id}_#{post_num}")
  user_id  = read_file_if_exist("./ip_addr/#{post_id}")
  user_name = read_file_if_exist("./user_name/#{user_id}")
  group_id  = read_file_if_exist("./group_id/#{user_id}")

  return {
    'type'      => MSG_TYPE,
    'post_num'  => post_num,
    'post_user' => user_name,
    'body'      => content,
    'time'      => time.strftime('%Y/%m/%d %H:%M:%S'),
    'ip_addr'   => user_id,
    'gid'       => group_id
  }
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

    type = ""
    if fp[1] == "TA"
      type = "only_TA"
    else
      type = MSG_TYPE
    end

    log_messages.push(JSON.generate({'type'=>type, 'post_num'=>fp[1], 'post_user'=>post_user,'body'=>content, 'time'=>time.strftime('%Y/%m/%d %H:%M:%S'),'ip_addr'=>unique_id, 'gid'=>group_id.to_i}))
  }
  return log_messages
end

mkdir_if_not_exist('./content')
mkdir_if_not_exist('./ip_addr')
mkdir_if_not_exist('./group_id')
mkdir_if_not_exist('./user_name')
mkdir_if_not_exist('./user_id')
mkdir_if_not_exist('./post_num')

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
        j = JSON.parse(msg)
        case j['type']
        # cookieに登録するシリアルナンバーを送る
        when 'cookie'
          req = j
          if req['unique_id'] == "TA"
            ta_id = process_ta()
            ta_cookie = JSON.generate({'type'=>'cookie', 'serial_num'=>ta_id})
            ws.send(ta_cookie)
          elsif req['unique_id'] == "NoData"
            unique_id = get_number()
            cookie = JSON.generate({'type'=>'cookie', 'serial_num'=>unique_id})
            ws.send(cookie)
          else
            user_data = get_regist_data(req['unique_id'])
            ws.send(user_data)
          end
        # 投稿内容を整理し，保存・配信する
        when 'comment'
          comment = j
          if comment['id'] == "000"
            zmsg = ip_zero(msg)
            ch.push(zmsg)
            $stderr.puts("#{sid}@#{ch_id} pushed a message '#{zmsg}'.")
          else
            post_num = post_num + 1
            post_id = store_post(post, post_num)
            loaded_post = JSON.generate(load_post(post_id))
            ch.push(loaded_post)
            $stderr.puts("#{sid}@#{ch_id} pushed a message '#{loaded_post}'.")
          end
        when 'user_name', 'user_id'
          user = j
          regist(user);
          user_data = get_regist_data(user['id'])
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
