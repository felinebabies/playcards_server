$(document).ready(function(){
  // ui設定
  $(".jquery-ui-button").button();
  // 残り枚数を表示する
  getCardLeftCount();

  $("#drawcardbutton").click(function(){
    // ajaxでカードを一枚引く
    var carddesignstr = "standard";
    if($('input[name=carddesign]:checked').val() === 'monacoin'){
      carddesignstr = "monachar";
    }
    var jsonsuccess = false;
    var result = $.ajax({
      type: 'POST',
      url: '/drawcard',
      data: {
        textcomment: $("#textcomment").val(),
        deletepassword: $("#deletepassword").val(),
        carddesign: carddesignstr
      },
      async: false,
      success: function(data) {
        jsonsuccess = true;
      },
      error: function(XMLHttpRequest, textStatus, errorThrown) {
        setFlashMessage("エラーが発生しました。  " +
          "XMLHttpRequest : " + XMLHttpRequest.status + " " +
          "textStatus : " + textStatus + " " +
          "errorThrown : " + errorThrown.message);
      }
    }).responseText;

    // エラーなら終了
    if(jsonsuccess == false){
      return;
    }

    var carddata = $.parseJSON(result)

    // コメント入力欄の内容を消去する
    textcomment: $("#textcomment").val("");

    $(".cardresult").slideUp(500,function(){
      // カードが尽きていなければ結果を表示する
      if(carddata["type"] != "empty") {
        // テキスト変更
        $("p.carddrawntext").text(carddata["type"] + "の" + carddata["num"] );

        // 画像変更
        $("p.carddrawnimg img").remove();
        $("p.carddrawnimg").append('<img src="' + carddata["imgurl"]  + '" width="200" height="300" alt="" />')

        // 結果を開く
        $(".cardresult").slideDown(500);
      }
      else{
        alert("山札の残り枚数が0です。")
      }
      // 残り枚数表示を更新する
      getCardLeftCount();

      // 今までに引いたカード一覧を更新する
      updateRecentCards();
    });

  });

  // シャッフルボタンの処理
  $("#shufflebutton").click(function(){
    var result = $.ajax({
      type: 'GET',
      url: '/shuffle',
      async: false
    }).responseText;
    var deckdata = $.parseJSON(result)

    // 残り枚数表示を更新する
    getCardLeftCount();

    // フラッシュメッセージを表示する
    setFlashMessage("山札をシャッフルしました。")

  });

  $("#addcommentdialog").dialog({
    autoOpen: false,
    width: 550,
    show: 'explode',
    hide: 'explode',
    modal: true,
    buttons: {
      "投稿": function(){
        // ajaxでコメントを投稿する
        var jsonsuccess = false;
        var result = $.ajax({
          type: 'POST',
          url: '/addcomment',
          data: {
            textcomment: $("#addcommenttext").val(),
            deletepassword: $("#addcommentpass").val(),
            targetid: $("#addcommentdialog").data("recentcardid")
          },
          async: false,
          success: function(data) {
            jsonsuccess = true;
          },
          error: function(XMLHttpRequest, textStatus, errorThrown) {
            setFlashMessage("エラーが発生しました。  " +
              "XMLHttpRequest : " + XMLHttpRequest.status + " " +
              "textStatus : " + textStatus + " " +
              "errorThrown : " + errorThrown.message);
          }
        }).responseText;

        // エラーなら終了
        if(jsonsuccess == false){
          return;
        }

        var commentstatus = $.parseJSON(result)

        // コメント入力欄の内容を消去する
        textcomment: $("#addcommenttext").val("");

        if(commentstatus["status"] == "success"){
          setFlashMessage("コメントの投稿を受け付けました。");
          updateRecentCards();
        } else {
          setFlashMessage("コメントを投稿することができませんでした。");
        }
        $(this).dialog("close");
      },
      "キャンセル": function() {
        $(this).dialog("close");
      }
    }
  });

  $("#deletecommentdialog").dialog({
    autoOpen: false,
    width: 550,
    show: 'explode',
    hide: 'explode',
    modal: true,
    buttons: {
      "削除実行": function(){
        // ajaxで削除を投げる
        var result = $.ajax({
          type: 'POST',
          url: '/deletecomment',
          data: {
            deletepassword: $("#deletecommentpass").val(),
            commentid: $("#deletecommentdialog").data("commentid")
          },
          async: false,
          success: function(data) {
            jsonsuccess = true;
          },
          error: function(XMLHttpRequest, textStatus, errorThrown) {
            setFlashMessage("エラーが発生しました。  " +
              "XMLHttpRequest : " + XMLHttpRequest.status + " " +
              "textStatus : " + textStatus + " " +
              "errorThrown : " + errorThrown.message);
          }
        }).responseText;

        // エラーなら終了
        if(jsonsuccess == false){
          return;
        }

        var deletestatus = $.parseJSON(result)

        if(deletestatus["status"] == "success"){
          setFlashMessage("コメントの削除を受け付けました。");
          updateRecentCards();
        } else {
          setFlashMessage("コメントを削除することができませんでした。");
        }
        $(this).dialog("close");
      },
      "キャンセル": function() {
        $(this).dialog("close");
      }
    }
  });

  // コメント返信ボタンの処理
  setAddCommentEvent();
});
