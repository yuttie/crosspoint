#!/bin/env ruby
# -*- coding: utf-8 -*-

require 'json'
require 'MeCab'

# 単語の必要な品詞とかでクラスを作る
class WordClass
  def initialize(word,pos1,pos2,origin)
    @word = word
    @pos1 = pos1
    @pos2 = pos2
    @origin = origin
  end

  def getword
    @word
  end
  def getpos1
    @pos1
  end
  def getpos2
    @pos2
  end
  def getorigin
    @origin
  end
end

def IDF(ni,n)
  if ni.to_f > 0.0 then
    idf = Math::log(n.to_f/ni.to_f)
    return idf
  else
    return 0.0
  end
end

def parse_contentMKHD_words_with_pos(sentence, sizeOneRM = false)
  mecab = MeCab::Tagger.new
  node = mecab.parseToNode(sentence)

  wordsArray = Array.new()
  while node do
    # p node.surface.force_encoding("UTF-8")
    # print node.feature,"\n"
    featureList = node.feature.split(",")
    pos1 = featureList[0].force_encoding("UTF-8")
    pos2 = featureList[1].force_encoding("UTF-8")
    # 名詞・形容詞・副詞のみを使う
    if pos1 == "名詞" || pos1 == "形容詞" || pos1 == "副詞" || pos1 == "動詞" then
      # 接尾語じゃないものしか使わない
      if pos2 != "接尾" then
        model_type = featureList[6].force_encoding("UTF-8")
        if model_type.size == 0 || model_type == "*" then
          model_type = node.surface.force_encoding("UTF-8")
        end
        # サ変接続は使わない　数も使わない
        if pos2 != "サ変接続" && pos2 != "数" then
          wordClass = WordClass.new(node.surface.force_encoding("UTF-8"),pos1,pos2,model_type)
          if sizeOneRM != false then
            wordsArray.push(wordClass) if model_type.size > 1
          else
            wordsArray.push(wordClass)
          end
        end
      end
    end
    node = node.next
  end
  return wordsArray
end

#与えられた配列orテキストから出現回数を求める関数
def getTermFreqencyForBM(input_text)
  # 形態素解析とBag of Words モデル作成
  tf = Hash.new(0)
  tfSum = 0
  input_text.each do |word|
    tf[word] += 1
    tfSum += 1
  end
  return {tf:tf,tfLength:tfSum}
end

def eval_length(res)
  max_th = 256
  eval_len = 0
  res_len = res.strip.size

  if res_len == 0
    eval_len = 0
  elsif res_len > max_th
    eval_len = 0
  else
    eval_len = res_len.to_f/max_th.to_f
  end

  return eval_len
end

def eval_tf_length(tf)
  max_th = 100
  eval_tf_len = 0
  res_tf_len = tf[:tf].size

  if res_tf_len == 0
    eval_tf_len = 0
  elsif res_tf_len > max_th
    eval_tf_len = 0
  else
    eval_tf_len = res_tf_len.to_f/max_th.to_f
  end

  return eval_tf_len
end

def eval_info(tf,marge_df,df_max)
  sum_info = 0
  tf[:tf].each do |word,value|
    df = 0
    df = marge_df[word] if !(marge_df[word].nil?)
    idf = IDF(df,df_max)
    sum_info += (value.to_f * idf.to_f)
  end
  return sum_info
end

def eval_pn_norn(word_list_pos, pn_table = JSON.load(open("/Users/yusuke_h/Research/Data/PNTable/pnTable.json")))
  pn_include = false
  noun_include = false
  word_list_pos.each do |wordClass|
    word = wordClass.getword
    if !(pn_table[word].nil?)
      pn_include = true
      noun_include = true if (word_list_pos.map { |e| e.getpos1 }).include?("名詞")
      break
    end
  end
  if pn_include
    pn_include_value = 1
  else
    pn_include_value = 0
  end
  if noun_include
    noun_include_value = 1
  else
    noun_include_value = 0
  end
  return {pn_include_value:pn_include_value, noun_include_value:noun_include_value}
end

def eval_res_value(res,marge_df,df_max,pn_table)
  res_len = eval_length(res)
  word_list_pos = parse_contentMKHD_words_with_pos(res,1)

  tf = getTermFreqencyForBM(word_list_pos.map{|e| e.getword})
  res_info = eval_info(tf,marge_df,df_max)
  res_tf_len = eval_tf_length(tf)

  res_pn_norn = eval_pn_norn(word_list_pos,pn_table)

  res_value = res_len * res_info * res_tf_len * res_pn_norn[:pn_include_value] * res_pn_norn[:noun_include_value]
  res_eval = {res_value:res_value, res_len:res_len, res_info:res_info, res_tf_len:res_tf_len, res_pn_norn:res_pn_norn}
  return res_eval
end
