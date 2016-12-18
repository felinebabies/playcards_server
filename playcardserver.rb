# coding: utf-8
require 'bundler'
Bundler.require

require "json"
require_relative './lib/playcards/playcards.rb'

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

  #トップページ
  get '/' do
    haml :index
  end

  #json カードを一枚引く
  get '/drawcard' do
    cards = Playcards.new
    card = cards.getcardinfo(cards.draw)
    card[:imgurl] = getcardimagepath(card[:type], card[:num])
    if card == nil then
      #カードが尽きた場合
      card = {:type => "empty", :num => "0"}
    end
    card.to_json
  end

  # Rubyファイルが直接実行されたらサーバを立ち上げる
  run! if app_file == $0
end
