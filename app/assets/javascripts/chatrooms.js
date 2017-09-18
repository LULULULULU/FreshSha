
var gamedata = 'soemthing';

$(document).on('turbolinks:load', function() {
  submitNewMessage();
  var gamedata = 'soemthing';
  var panel = document.getElementById('info-panel');
  panel.style.display = 'none';
});

function submitNewMessage(){
  $('textarea#message_content').keydown(function(event) {
    if (event.keyCode == 13) {
        $('[data-send="message"]').click();
        $('[data-textarea="message"]').val(" ")
        return false;
     }
  });
}

function lastnightinfo() {
  var panel = document.getElementById('info-panel');
  if (panel.style.display === 'none') {
      panel.style.display = 'block';
  } else {
      panel.style.display = 'none';
  }
}

