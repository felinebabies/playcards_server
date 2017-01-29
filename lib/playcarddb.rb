# coding: utf-8
require 'bundler'
Bundler.require
require "securerandom"
require 'digest/sha1'
require 'json'

#トランプの山札情報を格納するデータベース管理モジュール
module PlayCardDb
	DBFILENAME = "playcards.db"
	def createtable
		createdecksql = <<-SQL
		CREATE TABLE PLAY_CARD_DECK (
			id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
			shuffletime text NOT NULL,
			deckjson text NOT NULL
		);
		SQL

		createdrawcardsql = <<-SQL
		CREATE TABLE DRAW_CARD (
			id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
			drawtime text NOT NULL,
			deck_id integer NOT NULL,
			card_id integer NOT NULL
		);
		SQL

		createcommentsql = <<-SQL
		CREATE TABLE CARD_COMMENT (
			id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
			posttime text NOT NULL,
			drawcard_id integer NOT NULL,
			comment text NOT NULL,
			passwordhash text NOT NULL,
			salt text NOT NULL
		);
		SQL
		db = SQLite3::Database.new(DBFILENAME)

		tables = db.execute("SELECT tbl_name FROM sqlite_master WHERE type == 'table'").flatten

		db.execute_batch(createdecksql) unless tables.include?("PLAY_CARD_DECK")
		db.execute_batch(createdrawcardsql) unless tables.include?("DRAW_CARD")
		db.execute_batch(createcommentsql) unless tables.include?("CARD_COMMENT")

		db.close
	end

	#必要なテーブルがあるかを確認する
	def tableexists?
		db = SQLite3::Database.new(DBFILENAME)
		tables = db.execute("SELECT tbl_name FROM sqlite_master WHERE type == 'table'").flatten

		if tables.include?("PLAY_CARD_DECK") && tables.include?("DRAW_CARD") && tables.include?("CARD_COMMENT") then
				allexist = true
		else
				allexist = false
		end

		db.close

		return allexist
	end

	#最新のシャッフル済デッキを検索する
	def getnewestdeck
		selectsql = "SELECT * FROM PLAY_CARD_DECK ORDER BY id desc limit 1"

		db = SQLite3::Database.new(DBFILENAME)
		deckrecord = db.execute(selectsql)
		if deckrecord.count == 0 then
			return nil
		end

		#シャッフル済みデッキのjsonオブジェクトを配列に変換して返す
		deckjson = deckrecord.first[2]
		deckarr = JSON.parse(deckjson)

		deckobj = {
			id: deckrecord.first[0],
			date: deckrecord.first[1],
			deckarr: deckarr
		}

		return deckobj
	end

	#json形式で受け取った新しいシャッフル済みデッキを保存する
	def savedeckrecord(deckarrjson)
		insertsql = <<-SQL
			INSERT INTO PLAY_CARD_DECK
				VALUES (
					NULL,
					?,
					?
				)
		SQL
		db = SQLite3::Database.new(DBFILENAME)
		db.execute(insertsql,
			Time.now.strftime("%Y-%m-%d %X"),
			deckarrjson
		)
		db.close
	end

	#引いたカードの情報を保存する
	def savecardrecord(deckid, cardid)
		insertsql = <<-SQL
			INSERT INTO DRAW_CARD
				VALUES (
					NULL,
					?,
					?,
					?
				)
		SQL
		db = SQLite3::Database.new(DBFILENAME)
		db.execute(insertsql,
			Time.now.strftime("%Y-%m-%d %X"),
			deckid,
			cardid
		)
		db.close
	end

	#指定したIDの山札で、今までに引いたカードを取得する
	def getalreadydrawnbyid(deckid)
		selectsql = "SELECT * FROM DRAW_CARD WHERE deck_id = ?"

		db = SQLite3::Database.new(DBFILENAME)
		cardrecords = db.execute(selectsql,
			deckid)
		db.close

		cardsobjarr = cardrecords.map do |item|
			cardobj = {
				id: item[0],
				drawtime: item[1],
				deckid: item[2],
				cardid: item[3]
			}
			cardobj
		end

		return cardsobjarr
	end

	#今までに引いたカードを新しい方から指定枚数取得する
	def getalreadydrawn(limit = nil)
		db = SQLite3::Database.new(DBFILENAME)
		if limit != nil then
			selectsql = "SELECT * FROM DRAW_CARD ORDER BY id desc LIMIT ?"
			cardrecords = db.execute(selectsql,	limit)
		else
			selectsql = "SELECT * FROM DRAW_CARD ORDER BY id desc"
			cardrecords = db.execute(selectsql)
		end

		db.close

		cardsobjarr = cardrecords.map do |item|
			cardobj = {
				id: item[0],
				drawtime: item[1],
				deckid: item[2],
				cardid: item[3]
			}
			cardobj
		end

		return cardsobjarr
	end

	#引いたカードに対するコメントを記録する
	def savecardcomment(drawcard_id, commentstr, deletepassword)
		insertsql = <<-SQL
			INSERT INTO CARD_COMMENT
				VALUES (
					NULL,
					?,
					?,
					?,
					?,
					?
				)
		SQL

		# saltを生成する
		salt = self.generate_salt

		# 削除パスワードをハッシュ化する
		hashedPass = deletepassword.crypt(salt)

		db = SQLite3::Database.new(DBFILENAME)
		db.execute(insertsql,
			Time.now.strftime("%Y-%m-%d %X"),
			drawcard_id,
			commentstr,
			hashedPass,
			salt
		)
		db.close
	end

	#カードに対してついたコメントを検索して返す
	def getcardcommentbycardsobj(cardsobj = [])
		if cardsobj.empty? then
			return nil
		end
		if cardsobj.length <= 1 then
			selectsql = "SELECT * FROM CARD_COMMENT WHERE drawcard_id = ? ORDER BY id desc"
			idliststr = cardsobj.first[:id].to_s
		else
			idarr = cardsobj.map{|i| i[:id]};
			selectsql = "SELECT * FROM CARD_COMMENT WHERE "
			idarr.each_with_index do |item,idx|
				if idx > 0 then
					selectsql += "OR "
				end
				selectsql += "drawcard_id = ? "

			end
			selectsql += "ORDER BY id desc"
		end

		db = SQLite3::Database.new(DBFILENAME)
		if cardsobj.length <= 1 then
			commentrecords = db.execute(selectsql, idliststr)
		else
			commentrecords = db.execute(selectsql, idarr)
		end
		db.close

		commentobjarr = commentrecords.map do |item|
			commentobj = {
				id: item[0],
				postime: item[1],
				drawcardid: item[2],
				commentstr: item[3]
			}
			commentobj
		end
		return commentobjarr
	end

	def generate_salt
	  Digest::SHA1.hexdigest("#{Time.now.to_s}")
	end

	module_function :createtable
	module_function :tableexists?
	module_function :getnewestdeck
	module_function :savedeckrecord
	module_function :savecardrecord
	module_function :getalreadydrawnbyid
	module_function :getalreadydrawn
	module_function :savecardcomment
	module_function :getcardcommentbycardsobj
	module_function :generate_salt
end

if __FILE__ == $0 then
	require_relative "playcards/playcards.rb"

	currentdir = File.dirname(__FILE__)
	dbfilepath = File.join(currentdir, PlayCardDb::DBFILENAME)
	# テスト用DBが残っていれば削除
	FileUtils.rm(dbfilepath) if File.exists?(dbfilepath)

	puts "新しくテーブルを生成します"
	unless PlayCardDb.tableexists? then
		PlayCardDb.createtable
	end

	puts "最新のデッキを取得　nilが帰ってくれば成功"
	if PlayCardDb.getnewestdeck() == nil then
		puts "nilが帰ってきました"
	else
		puts "nil以外が帰ってきました"
	end

	puts "新しくシャッフルしたデッキをDBに登録します"
	cards = Playcards.new
	PlayCardDb.savedeckrecord(cards.getjson())

	puts "最新のデッキを取得　nilではないオブジェクトが帰ってくれば成功"
	deckobj = PlayCardDb.getnewestdeck()
	if deckobj == nil then
		puts "nilが帰ってきました"
	else
		puts "nil以外が帰ってきました"
		puts deckobj
	end

	puts "DBを元に新しい山札を作りました"
	cards2 = Playcards.new(deckobj[:deckarr], 0)

	puts "新しい山札からすべてのカードを引きます"
  until (card = cards2.draw) == nil do
    print card.to_s + ","
  end

	puts "DBを元に別の新しい山札を作りました"
	cards3 = Playcards.new(deckobj[:deckarr], 0)

	puts "一枚カードを引き、DBにセーブします"
	card = cards3.draw
	puts "カード#{cards3.getcardinfo(card)}を引きました"
	PlayCardDb.savecardrecord(deckobj[:id], card)
	puts "カード#{cards3.getcardinfo(card)}をDBに保存しました"

	puts "DBから、今まで引いたカードを取得します"
	drawnarr = PlayCardDb.getalreadydrawn()
	puts drawnarr
	puts "DBから、今まで引いたカードをデッキIDを指定して取得します"
	drawnarr = PlayCardDb.getalreadydrawnbyid(1)
	puts drawnarr

	puts "もう一枚カードを引き、DBにセーブします"
	card = cards3.draw
	puts "カード#{cards3.getcardinfo(card)}を引きました"
	PlayCardDb.savecardrecord(deckobj[:id], card)
	puts "カード#{cards3.getcardinfo(card)}をDBに保存しました"

	puts "DBから、今まで引いたカードを取得します"
	drawnarr = PlayCardDb.getalreadydrawn()
	p drawnarr

	puts "引いたカードに対するコメントをつけます"
	PlayCardDb.savecardcomment(drawnarr.first[:id], "テストコメント1です。", "hoge")
	PlayCardDb.savecardcomment(drawnarr.first[:id], "テストコメント2です。", "hoge")

	puts "コメントを確認します"
	p PlayCardDb.getcardcommentbycardsobj([drawnarr.first[:id]])

end
