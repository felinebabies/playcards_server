# coding: utf-8
require 'bundler'
Bundler.require

require "json"
require_relative './lib/playcards/playcards.rb'
require_relative './lib/playcarddb.rb'

# コメント削除パスワードが正しいかを判定する
def valid_deletepath?(commentid, deletepass)
	commentobj = PlayCardDb.getcardcommentbyid(commentid)

	# 削除パスワードをハッシュ化する
	hashedPass = deletepass.crypt(commentobj[:salt])

	hashedPass == commentobj[:passwordhash]
end

class PlayCardsServer < Sinatra::Base
  register Sinatra::Reloader

  #ヘルパー定義
	helpers do
		#サニタイズ用関数を使用する用意
		include Rack::Utils
		alias_method :h, :escape_html
	end

  helpers do
    #カード情報から、カード画像へのパスを返す
    def getcardimagepath(type, number, design = "standard")
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

      return "/image/#{design}/" + imgname
    end
  end

  # 最近に引いた10枚分のカードの履歴とコメントを返す
  def getrecentcards(limit = 10)
    recentcards = PlayCardDb.getalreadydrawn(limit)

    # カードについたコメントを検索する
    commentsobj = []
    if recentcards.length >= 1 then
      cardidarr = recentcards.map do |carditem|
        carditem[:id]
      end
      commentsobj = PlayCardDb.getcardcommentbycardsobj(recentcards)
    end
    commentsobj = [] if commentsobj == nil

    cards = Playcards.new()

    recentcards.map! do |carditem|
      # カードの情報を取得する
      carditem[:cardtype] = cards.getcardinfo(carditem[:cardid])
      carditem[:comments] = commentsobj.select do |commentitem|
        commentitem[:drawcardid] == carditem[:id]
      end

      carditem
    end

    return recentcards
  end

  #トップページ
  get '/' do
    # データベースにテーブルが存在しなければ追加
  	unless PlayCardDb.tableexists? then
  		PlayCardDb.createtable
  	end
		
    @recentarr = getrecentcards()
		@importjsarr = ["/js/index.js"]
    haml :index
  end

  #json カードを一枚引く
  post '/drawcard' do
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

      # カードの図柄指定があれば設定する
      designtype = "standard"
      if params[:carddesign] != nil then
        case params[:carddesign]
        when "monachar" then
          designtype = "mona_char_card"
        else
          designtype = "standard"
        end
      end

      # カードの情報を取得する
      cardinfo = cards.getcardinfo(card)
      cardinfo[:imgurl] = getcardimagepath(cardinfo[:type], cardinfo[:num], designtype)

      # コメントが付属していた場合、コメントを登録する
      if params[:textcomment] != nil && (!params[:textcomment].empty?) then
        commentdrawnarr = PlayCardDb.getalreadydrawn(1)
        drawncardid = commentdrawnarr.first[:id]
        PlayCardDb.savecardcomment(drawncardid, params[:textcomment], params[:deletepassword])
      end

    end

    cardinfo.to_json
  end

	# コメント一覧ページを表示する
	get '/allcomments' do
    # データベースにテーブルが存在しなければ追加
  	unless PlayCardDb.tableexists? then
  		PlayCardDb.createtable
  	end

		#コメント、カードの全記録を取得する
    @recentarr = getrecentcards(0)
		@importjsarr = ["/js/allcomments.js"]
    haml :allcomments
	end

  #既存のカードにコメントを投稿する
  post '/addcomment' do
    # データベースにテーブルが存在しなければ追加
  	unless PlayCardDb.tableexists? then
  		PlayCardDb.createtable
  	end

    commentstatus = ""
    # コメントが付属していた場合、コメントを登録する
    if params[:textcomment] != nil && (!params[:textcomment].empty?) then
      drawncardid = params[:targetid]
      PlayCardDb.savecardcomment(drawncardid, params[:textcomment], params[:deletepassword])

      commentstatus = "success"
    else
      commentstatus = "failed"
    end

    {:status => commentstatus}.to_json
  end

  #今までに引いたカードとコメントの一覧を返す
  get '/recentcards' do
    # データベースにテーブルが存在しなければ追加
  	unless PlayCardDb.tableexists? then
  		PlayCardDb.createtable
  	end

    @recentarr = getrecentcards()
    haml :_recentcomments, :layout => nil
  end

  #デッキをシャッフルして結果を返す
  get '/shuffle' do
    # データベースにテーブルが存在しなければ追加
  	unless PlayCardDb.tableexists? then
  		PlayCardDb.createtable
  	end

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

  #コメントを削除する
  post '/deletecomment' do
    # データベースにテーブルが存在しなければ追加
  	unless PlayCardDb.tableexists? then
  		PlayCardDb.createtable
  	end

    status = ""
		if valid_deletepath?(params[:commentid], params[:deletepassword]) then
			PlayCardDb.setcommentvalid(0, params[:commentid])
			status = "success"
		else
      status = "failed"
		end

    returnobj = {
      :status => status
    }

		returnobj.to_json
  end

  # Rubyファイルが直接実行されたらサーバを立ち上げる
  run! if app_file == $0
end
