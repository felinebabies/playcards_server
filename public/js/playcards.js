function setFlashMessage(textmessage){
  $(".flashmessage p").text(textmessage);
  $(".flashmessage").slideDown(function(){
    setTimeout(function(){
      $(".flashmessage").slideUp();
    }, 3000);
  });
}

// 山札のカードの残数を取得する
function getCardLeftCount(){
  var result = $.ajax({
    type: 'GET',
    url: location.href + '/deckleft',
    async: false
  }).responseText;
  var leftdata = $.parseJSON(result);

  $("p.cardleftcount").text("残り" + leftdata["left"] + "枚");
}

function setAddCommentEvent(){
  $(".addcomment").click(function(){
    // コメント対象のIDを設定
    var targetcardid = $(this).data("recentcardid");
    $("#addcommentdialog").data("recentcardid", targetcardid);
    // コメント投稿用ダイアログを作って開く
    $("#addcommentdialog").dialog("open");
  });
}

function updateRecentCards(){
  var result = $.ajax({
    type: 'GET',
    url: location.href + '/recentcards',
    async: false
  }).responseText;

  $("#recentComments").html(result);
  setAddCommentEvent();
}

$(document).ready(function(){
  // ui設定
  $(".jquery-ui-button").button();
  // 残り枚数を表示する
  getCardLeftCount();

  $("#drawcardbutton").click(function(){
    // ajaxでカードを一枚引く
    var result = $.ajax({
      type: 'POST',
      url: location.href + '/drawcard',
      data: {
        textcomment: $("#textcomment").val(),
        deletepassword: $("#deletepassword").val()
      },
      async: false
    }).responseText;
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
      url: location.href + '/shuffle',
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
        var result = $.ajax({
          type: 'POST',
          url: location.href + '/addcomment',
          data: {
            textcomment: $("#addcommenttext").val(),
            deletepassword: $("#addcommentpass").val(),
            targetid: $("#addcommentdialog").data("recentcardid")
          },
          async: false
        }).responseText;
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

  // コメント返信ボタンの処理
  setAddCommentEvent();
});
