$(document).ready(function(){
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
    });

  });
});
