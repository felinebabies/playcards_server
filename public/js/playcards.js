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
    url: '/deckleft',
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
  $(".deletecomment").click(function(){
    // コメント対象のIDを設定
    var targetcommentid = $(this).data("commentid");
    $("#deletecommentdialog").data("commentid", targetcommentid);
    // コメント本文をダイアログに設定
    $("#targetcommentstr").text($(this).prev(".commentbody").text());
    // コメント投稿用ダイアログを作って開く
    $("#deletecommentdialog").dialog("open");
  });
}

//最近引いたカードとコメントの一覧を更新する
function updateRecentCards(){
  var result = $.ajax({
    type: 'GET',
    url: '/recentcards',
    async: false
  }).responseText;

  $("#recentComments").html(result);
  setAddCommentEvent();
}
