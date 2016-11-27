# coding: utf-8
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
		else

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
	def getalreadydrawn(deckid)
		selectsql = "SELECT * FROM DRAW_CARD WHERE deck_id = ?"

		db = SQLite3::Database.new(DBFILENAME)
		cardrecords = db.execute(selectsql,
			deckid)
		db.close

		cardsobj = cardrecords.map do |item|
			cardobj = {
				id: item[0],
				drawtime: item[1],
				cardid: item[2]
			}
			return cardobj
		end

		return cardsobj
	end

	module_function :createtable
	module_function :tableexists?
	module_function :getnewestdeck
	module_function :savedeckrecord
	module_function :savecardrecord
end
