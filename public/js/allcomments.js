$(document).ready(function(){
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
        var jsonsuccess = false;
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
