$(document).on("turbolinks:load", function () {  
  App.messages = App.cable.subscriptions.create({
    channel: 'MessagesChannel', 
    chatroom_name: $('.data-div #message_room_name').val()
  }, {  
    received: function(data) {
      $("#messages").removeClass('hidden')
      // console.log(data)
      var gamedata = JSON.parse(data.message);
      // console.log(gamedata)

      previousdata = this.getCurrentRoomMessage();


      this.updateSeats(gamedata);

      return $('#messages').html(this.renderMessage(data));
    },

    renderMessage: function(data) {
      return "<p> <b>" + data.user + ": </b>" + data.message + "</p>";
    },

    getRoomName: function() {
      return $('.data-div #message_room_name').val();
    },

    getCurrentUserId: function() {
      return $('.data-div #message_this_user_id').val();
    },

    getCurrentUserName: function() {
      return $('.data-div #message_this_user_name').val();
    },

    getCurrentRoomMessage: function() {
      return $('.data-div #message_current_message_content').val();
    },

    setCurrentRoomMessage: function(string) {
      return $('.data-div #message_current_message_content').val(string);
    },

    updateSeats: function(data) {
      var user;
      for(i = 1; i <= data['room_size']; i++) { 
        user = data['seats'][i]['user'];
        if (user === 'EMPTY_SEAT_USER') {
          $("#seat-"+i).addClass("btn-success");
          $("#seat-"+i).removeClass("btn-secondary");
          $("#seat-label-"+i).html('空');
        } else {
          $("#seat-"+i).addClass("btn-secondary");
          $("#seat-"+i).removeClass("btn-success");
          $("#seat-label-"+i).html(user);
        }
      }
    }
  });
});