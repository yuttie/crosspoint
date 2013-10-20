#!/usr/bin/ruby -Ku
# vim: set fileencoding=utf-8:
if RUBY_VERSION >= '1.9'
  Encoding.default_external = Encoding::UTF_8
end

require 'rubygems'
require 'bundler/setup'

require './eval/eval_res.rb'
require 'em-websocket'
require 'json'
require 'fileutils'
require 'cgi'


def log(sid, ch_id, msg)
  $stderr.puts("#{sid}@#{ch_id}: #{msg}")
end

def mkdir_if_not_exist(dp)
  Dir.mkdir(dp) unless Dir.exist?(dp)
  raise "Couldn't make a directory '#{dp}'." unless Dir.exist?(dp)
end

def read_file_if_exist(fp)
  File.exist?(fp) ? IO.read(fp) : nil
end

def generate_id_from_time
  time = Time.now
  id = (time.to_r * 1000000000).to_i.to_s
  [id, time]
end

def create_user(enum)
  user = { 'user_id' => generate_id_from_time[0], 'group_id' => enum.next }
  save_user(user)
  user
end

def save_user(user)
  mkdir_if_not_exist('./user')
  IO.write("user/#{user['user_id']}", JSON.generate(user))
  nil
end

def load_user(user_id)
  mkdir_if_not_exist('./user')
  fp = "./user/#{user_id}"
  if File.exist?(fp)
    JSON.parse(IO.read(fp))
  else
    nil
  end
end

def load_or_recreate_user(uid, enum)
  user = load_user(uid)
  if !user
    user = { 'user_id' => uid, 'group_id' => enum.next }
    save_user(user)
  end

  user
end

def stamp_post(post)
  post['post_id'], post['time'] = generate_id_from_time
  post['number'] = Dir.glob("./post/*").length + 1

  post
end

def save_post(post)
  mkdir_if_not_exist('./post')
  IO.write("./post/#{post['post_id']}", JSON.generate(post))
  nil
end

def load_post(post_id)
  mkdir_if_not_exist('./user')
  fp = "./post/#{post_id}"
  if File.exist?(fp)
    JSON.parse(IO.read(fp))
  else
    nil
  end
end

def load_latest_posts(n)
  Dir.glob('./post/*').map {|fp| File.basename(fp).to_i }\
    .sort_by {|post_id_num| -post_id_num }.lazy\
    .map {|post_id_num| load_post(post_id_num) }\
    .select {|post| post }\
    .take(n)\
    .to_a\
    .reverse
end

def sanitize_post(post)
  if post
    # sanitize
    post['content'] = CGI.escapeHTML(post['content'])
  end

  post
end

class Analyzer
  def initialize
    #@user_num_posts = Hash.new(0)
    #@marge_df = JSON.load(open("./eval/data/marge_df.json"))
    #@df_max = @marge_df.max { |a, b| a[1] <=> b[1] }[1]
    #@pn_table = JSON.load(open("./eval/data/pnTable.json"))
  end
  def analyze(msg)
    #case msg['type']
    #when 'comment'
    #  comment = msg
    #  @user_num_posts[comment['post_id']] += 1
    #  p res_eval = eval_res_value(comment['content'], @marge_df, @df_max, @pn_table)

    #  result = ""
    #  if res_eval[:res_value] > 0.05
    #    result <<  "<span style=\"color: red\">\"#{CGI.escapeHTML(comment['content'])}\"</span>"
    #  end
    #  # if comment['content'] =~ /#GROUP-ONLY/i
    #  #   result << "グループ書き込み<span style=\"color: red\">\"#{CGI.escapeHTML(comment['content'])}\"</span>を観測しました。"
    #  # else
    #  #   result << "書き込み<span style=\"color: red\">\"#{CGI.escapeHTML(comment['content'])}\"</span>を観測しました。"
    #  # end
    #  # result << "<br>"
    #  # result << "<div style=\"margin: 1em 0; padding: 0.5em; border: 1px solid gray; border-radius: 4px;\">"
    #  # result << "<div style=\"font: bold 1.2em serif\">統計:</div>"
    #  # @user_num_posts.each {|uid, count|
    #  #   result << "<div class=\"stat\">ユーザID: #{uid}, 書き込み数: #{count}</div>"
    #  # }
    #  # result << "</div>"
    #  result
    #else
    #  nil
    #end
    nil
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

  # enumerator for group numbers
  sorting_hat = Enumerator.new {|y|
    gid = 1
    group_size_enum = [3, 6, 9].cycle.each {|group_size|
      group_size.times do
        y << gid.to_s
      end
      gid += 1
    }
  }
  sorting_hat.take(Dir.glob('./user/*').length)

  EventMachine::WebSocket.start(host: ARGV[1] || "0.0.0.0", port: (ARGV[0] || 9090).to_i) do |ws|
    ws.onopen {|handshake|
      ch_id = handshake.path
      @channels[ch_id] ||= EventMachine::Channel.new
      ch = @channels[ch_id]

      sid = ch.subscribe {|msg|
        ws.send(msg)
      }
      log(sid, ch_id, "connected")

      ws.onmessage {|msg|
        log(sid, ch_id, "message: #{msg}")
        data = JSON.parse(msg)

        # ask our bot to analyze the message
        msg_queue.push(data)
        msg_queue.pop {|msg|
          result = analyzer.analyze(msg)
          result_queue << result if result
        }
        result_queue.pop {|result|
          if result.size > 2
            msg = {
              'type'      => 'post',
              'number'    => 'TA',
              'user_name' => '解析ぼっと',
              'content'   => result + "#GROUP-ONLY",  # W/o escaping.
              'time'      => Time.now.strftime('%Y/%m/%d %H:%M:%S'),
              'user_id'   => 0,
              'group_id'  => 0
            }
            ch.push(JSON.generate(msg))
          end
        }

        # cookieに登録するシリアルナンバーを送る
        case data['type']
        when "need-both-ids"
          # make a new user
          user = create_user(sorting_hat)
          save_user(user)

          msg1 = { 'type' => 'user-id', 'user_id' => user['user_id'] }
          ws.send(JSON.generate(msg1))
          msg2 = { 'type' => 'group-id', 'group_id' => user['group_id'] }
          ws.send(JSON.generate(msg2))
        when "need-group-id"
          user = JSON.parse(IO.read("user/#{data['user_id']}"))
          if user
            # update existing user
            user['group_id'] = sorting_hat.next
          else
            # make a new user
            user = create_user(sorting_hat)
          end
          save_user(user)

          msg = { 'type' => 'group-id', 'group_id' => user['group_id'] }
          ws.send(JSON.generate(msg))
        when "post"
          post = stamp_post(data)
          save_post(post)

          uid = post['user_id']
          user = load_or_recreate_user(uid, sorting_hat)
          post['user'] = user
          post = sanitize_post(post)

          # multicast
          ch.push(JSON.generate(post))
        when 'change-screen-name'
          uid = data['user_id']
          user = load_or_recreate_user(uid, sorting_hat)
          user['screen_name'] = data['screen_name']
          save_user(user)
        when 'change-student-id'
          uid = data['user_id']
          user = load_or_recreate_user(uid, sorting_hat)
          user['student_id'] = data['student_id']
          save_user(user)
        else
          log(sid, ch_id, "unknown message type: #{data['type']}")
        end
      }

      ws.onclose {
        ch.unsubscribe(sid)
        log(sid, ch_id, "disconnected")
      }

      # send archived post
      posts = load_latest_posts(100).map {|post|
        uid = post['user_id']
        user = load_or_recreate_user(uid, sorting_hat)
        post['user'] = user

        sanitize_post(post)
      }
      ws.send(JSON.generate({"type" => "archived-posts", "posts" => posts}))
    }
  end
}
