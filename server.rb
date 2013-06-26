#!/usr/bin/ruby -Ku
# vim: set fileencoding=utf-8:
if RUBY_VERSION >= '1.9'
  Encoding.default_external = Encoding::UTF_8
end

require './eval/eval_res.rb'
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
  str.gsub!(/\n/, '<br>')
  str
end

# グループの振り分け
GROUP_NUM_LIST = [3,6,9]
TH = 3

def get_group_array(num)
  a = []
  i = 0
  while num >= GROUP_NUM_LIST[i % GROUP_NUM_LIST.length] + TH
  a += ([i + 1] * GROUP_NUM_LIST[i % GROUP_NUM_LIST.length])
  num = num - GROUP_NUM_LIST[i % GROUP_NUM_LIST.length]
  i = (i + 1)
  end
  a += ([i + 1] * num)
  a
end


def get_group_id(file_num)
  file_num += 1
  p group_array = get_group_array(file_num)
  p group_id = group_array[group_array.size - 1]
  rewrite_flag = false
  rewrite_flag = !(group_array[-TH-1] == group_array[-TH]) if !(group_array[-TH-1].nil?)
  p rewrite_flag
  puts ""
  if rewrite_flag
    id_list = []
    Dir.glob("./group_id/*") { |file| id_list.push(file)}
    id_list.sort[-2..-1].each do |file_path|
      outfile = open("#{file_path}","w")
      outfile.print group_id
      outfile.close
    end
  end
  return group_id
end

def get_number()
  time = Time.now
  serial_id = time.to_i.to_s + time.usec.to_s.rjust(6, '0')
  # これまでのファイル数でグループを割り振る
  dir_path = "./group_id"
  file_num = File.exist?(dir_path) ? `ls #{dir_path}|wc -l`.to_i : 0
  group_id = get_group_id(file_num)
  IO.write('./group_id/' + serial_id, group_id)
  return serial_id
end

def process_ta()
  time = Time.now
  serial_id = time.to_i.to_s + time.usec.to_s.rjust(6, '0')
  IO.write('./group_id/' + serial_id, "0")
  return serial_id
end

#TA投稿用
def ip_zero(msg)
  data = JSON.parse(msg)
  unique_id = data['id']
  #あえてエスケープをかけない. HTMLタグを使用可に.
  content = show_spaces(escape(data['body']))
  #content = data['body']

  time = Time.now
  post_id = time.to_i.to_s + time.usec.to_s.rjust(6, '0')
  IO.write("./content/"   + post_id + "_TA", content)
  IO.write('./ip_addr/'   + post_id, unique_id)
  group_id = read_file_if_exist("./group_id/#{unique_id}")

  post_user = read_file_if_exist("./user_name/#{unique_id}")
  if post_user == ""
    post_user = "NO NAME"
  end

  #JavaScriptに返す形式にmsgを整理
  new_msg = {'type'=>'only_TA', 'post_num'=>'TA', 'post_user'=>post_user, 'body'=>content, 'time'=>time.strftime('%Y/%m/%d %H:%M:%S'),'ip_addr'=>unique_id, 'gid'=>group_id}
  return new_msg
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
  group_id = read_file_if_exist("./group_id/#{unique_id}")

  post_user = read_file_if_exist("./user_name/#{unique_id}")
  if post_user == ""
    post_user = "NO NAME"
  end

  #JavaScriptに返す形式にmsgを整理
  new_msg = {'type'=>MSG_TYPE, 'post_num'=>num, 'post_user'=>post_user, 'body'=>content, 'time'=>time.strftime('%Y/%m/%d %H:%M:%S'),'ip_addr'=>unique_id, 'gid'=>group_id}
  return new_msg
end

#所見ユーザに過去の投稿を全て送信するために準備
def log_messages(n)
  log_messages = Array.new
  #保存されたメッセージの取得
  Dir.glob('./content/*').sort.last(n).each_with_index {|prefp, i|
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

    type = ""
    if fp[1] == "TA"
      type = "only_TA"
    else
      type = MSG_TYPE
    end

    log_messages.push({'type'=>type, 'post_num'=>fp[1], 'post_user'=>post_user,'body'=>content, 'time'=>time.strftime('%Y/%m/%d %H:%M:%S'),'ip_addr'=>unique_id, 'gid'=>group_id.to_i})
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

class Analyzer
  def initialize
    @user_num_posts = Hash.new(0)
    @marge_df = JSON.load(open("./eval/data/marge_df.json"))
    @df_max = @marge_df.max { |a, b| a[1] <=> b[1] }[1]
    @pn_table = JSON.load(open("./eval/data/pnTable.json"))
  end
  def analyze(msg)
    case msg['type']
    when 'comment'
      comment = msg
      @user_num_posts[comment['id']] += 1
      res_eval = eval_res_value(comment['body'], @marge_df, @df_max, @pn_table)

      result = ""
      if comment['body'] =~ /#GROUP-ONLY/i
        result << "グループ書き込み<span style=\"color: red\">\"#{escape(comment['body'])}\"</span>を観測しました。"
      else
        result << "書き込み<span style=\"color: red\">\"#{escape(comment['body'])}\"</span>を観測しました。"
      end
      result << "<br>"
      result << "<div style=\"margin: 1em 0; padding: 0.5em; border: 1px solid gray; border-radius: 4px;\">"
      result << "<div style=\"font: bold 1.2em serif\">統計:</div>"
      @user_num_posts.each {|uid, count|
        result << "<div class=\"stat\">ユーザID: #{uid}, 書き込み数: #{count}</div>"
      }
      result << "</div>"
      result
    else
      nil
    end
  end
  def decorate(comment)
    comment
  end
end

EventMachine.run {
  @channels = {}
  analyzer = Analyzer.new
  msg_queue = EM::Queue.new
  result_queue = EM::Queue.new

  EventMachine::WebSocket.start(host: ARGV[1] || "0.0.0.0", port: (ARGV[0] || 9090).to_i) do |ws|
    ws.onopen {|handshake|
      ch_id = handshake.path
      @channels[ch_id] ||= EventMachine::Channel.new
      ch = @channels[ch_id]

      #接続が区立されたユーザ１人に対して既存メッセージを送信する
      msgs = log_messages(100)
      ws.send(JSON.generate({"type" => "multiple-comments", "comments" => msgs}))

      sid = ch.subscribe {|msg|
        ws.send(msg)
      }
      $stderr.puts("#{sid} connected to #{ch_id}.")


      ws.onmessage {|msg|
        data = JSON.parse(msg)

        # ask our bot to analyze the message
        msg_queue.push(data)
        msg_queue.pop {|msg|
          result = analyzer.analyze(msg)
          result_queue << result if result
        }
        result_queue.pop {|result|
          m = {
            'type'      => 'only_TA',
            'post_num'  => 'TA',
            'post_user' => '解析ぼっと',
            'body'      => result,  # W/o escaping.
            'time'      => Time.now.strftime('%Y/%m/%d %H:%M:%S'),
            'ip_addr'   => 0,
            'gid'       => 0
          }
          ch.push(JSON.generate(m))
        }

        # cookieに登録するシリアルナンバーを送る
        if data['type'] == "cookie"
          if data['unique_id'] == "TA"
            ta_id = process_ta()
            ta_cookie = JSON.generate({'type'=>'cookie', 'serial_num'=>ta_id})
            ws.send(ta_cookie)
          elsif data['unique_id'] == "NoData"
            unique_id = get_number()
            cookie = JSON.generate({'type'=>'cookie', 'serial_num'=>unique_id})
            ws.send(cookie)
          else
            user_data = get_regist_data(data['unique_id'])
            ws.send(user_data)
          end
        # 投稿内容を整理し，保存・配信する
        elsif(data['type'] == "comment")
          if(data['id'] == "000")
            zmsg = analyzer.decorate(ip_zero(msg))
            ch.push(JSON.generate(zmsg))
            $stderr.puts("#{sid}@#{ch_id} pushed a message '#{zmsg}'.")
          else
            post_num = post_num + 1
            nmsg = analyzer.decorate(message(msg,post_num))
            ch.push(JSON.generate(nmsg))
            $stderr.puts("#{sid}@#{ch_id} pushed a message '#{nmsg}'.")
          end
        elsif data['type'] == 'question'
          zmsg = ip_zero(msg)
          ch.push(JSON.generate(zmsg))
          $stderr.puts("#{sid}@#{ch_id} pushed a message '#{zmsg}'.")
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
