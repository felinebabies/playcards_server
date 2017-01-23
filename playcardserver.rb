# coding: utf-8
require 'bundler'
Bundler.require

require "json"
require_relative './lib/playcards/playcards.rb'
require_relative './lib/playcarddb.rb'

class PlayCardsServer < Sinatra::Base
  register Sinatra::Reloader

  helpers do
    #カード情報から、カード画像へのパスを返す
    def getcardimagepath(type, number)
      imgname = ""
      case type
      when "heart" then
        imgname += "h"
      when "diamond" then
        imgname += "d"
      when "club" then
        imgname += "c"
      when "spade" then
        imgname += "s"
      when "joker" then
        imgname += "x"
      else
        return nil
      end

      if type == "joker" then
        imgname += format("%02d", 1)
      else
        imgname += format("%02d", number)
      end
      imgname += ".png"

      return "/image/" + imgname
    end
  end

  # 最近に引いた10枚分のカードの履歴を返す
  def getrecentcards(limit = 10)
    recentcards = PlayCardDb.getalreadydrawn(limit)

    cards = Playcards.new()

    recentcards.map! do |carditem|
      # カードの情報を取得する
      carditem[:cardtype] = cards.getcardinfo(carditem[:cardid])
      carditem[:comments] = [
        {:date => "2017-01-23 23:21:08", :str => "コメントテストです。"},
        {:date => "2017-01-23 23:21:09", :str => "コメントテスト2です。"}
      ]
      carditem
    end

    return recentcards
  end

  #トップページ
  get '/' do
    @recentarr = getrecentcards()
    haml :index
  end

  #json カードを一枚引く
  get '/drawcard' do
    # データベースにテーブルが存在しなければ追加
  	unless PlayCardDb.tableexists? then
  		PlayCardDb.createtable
  	end

    # 最新のデッキを確認し、デッキが無ければ新しくデッキを作る
  	deckobj = PlayCardDb.getnewestdeck()
  	if deckobj == nil then
    	newcards = Playcards.new
    	PlayCardDb.savedeckrecord(newcards.getjson())

      # 最新のデッキを取得する
    	deckobj = PlayCardDb.getnewestdeck()
    end

    # 登録済みのカードを検索する
  	drawnarr = PlayCardDb.getalreadydrawnbyid(deckobj[:id])
    drawncount = drawnarr.length

    cards = Playcards.new(deckobj[:deckarr], drawncount)
    card = cards.draw
    if card == nil then
      #カードが尽きた場合
      cardinfo = {:type => "empty", :num => "0"}
    else
      # 引いたカードをDBに登録する
      PlayCardDb.savecardrecord(deckobj[:id], card)

      # カードの情報を取得する
      cardinfo = cards.getcardinfo(card)
      cardinfo[:imgurl] = getcardimagepath(cardinfo[:type], cardinfo[:num])
    end

    cardinfo.to_json
  end

  #デッキをシャッフルして結果を返す
  get '/shuffle' do
    # データベースにテーブルが存在しなければ追加
  	unless PlayCardDb.tableexists? then
  		PlayCardDb.createtable
  	end

  	newcards = Playcards.new
  	PlayCardDb.savedeckrecord(newcards.getjson())

    # 最新のデッキを取得する
  	deckobj = PlayCardDb.getnewestdeck()

    deckinfoobj = {
      :id => deckobj[:id]
    }

    deckinfoobj.to_json
  end

  #デッキの残枚数を返す
  get '/deckleft' do
    # データベースにテーブルが存在しなければ追加
  	unless PlayCardDb.tableexists? then
  		PlayCardDb.createtable
  	end

    # 最新のデッキを取得する
  	deckobj = PlayCardDb.getnewestdeck()
    if deckobj == nil then
      	newcards = Playcards.new
      	PlayCardDb.savedeckrecord(newcards.getjson())
      	deckobj = PlayCardDb.getnewestdeck()
    end

    # 最新のデッキで既に引かれているカードを全て取得する
    drawnarr = PlayCardDb.getalreadydrawnbyid(deckobj[:id])

    returnobj = {
      :deckid => deckobj[:id],
      :left => (53 - drawnarr.count)
    }

    returnobj.to_json
  end

  # Rubyファイルが直接実行されたらサーバを立ち上げる
  run! if app_file == $0
end
