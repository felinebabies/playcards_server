# coding: utf-8
require 'bundler'
Bundler.require

require_relative './lib/playcards/playcards.rb'

class PlayCardsServer < Sinatra::Base
  register Sinatra::Reloader

  #トップページ
  get '/' do
    cards = Playcards.new
    @card = cards.getcardinfo(cards.draw)
    haml :index
  end

  # Rubyファイルが直接実行されたらサーバを立ち上げる
  run! if app_file == $0
end
