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
  var leftdata = $.parseJSON(result)

  $("p.cardleftcount").text("残り" + leftdata["left"] + "枚")
}

$(document).ready(function(){
  // 残り枚数を表示する
  getCardLeftCount();

  $("#drawcardbutton").click(function(){
    // ajaxでカードを一枚引く
    var result = $.ajax({
      type: 'GET',
      url: location.href + '/drawcard',
      async: false
    }).responseText;
    var carddata = $.parseJSON(result)

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
});
