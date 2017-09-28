var debug = true;

App.messages = App.cable.subscriptions.create('MessagesChannel', {  
  received: function(data) {
    $("#messages").removeClass('hidden')
    // console.log(data);
    var gamedata = JSON.parse(data.message);
    var data_msg_id = data.id;
    var current_msg_id = parseInt(this.getCurrentMessageId());

    if (data_msg_id === current_msg_id) {
      previousdata = this.getCurrentRoomMessage();
      this.updateSeats(gamedata);
      this.setCurrentRoomMessage(data.message)
      return $('#messages').html(this.renderMessage(data));
    }
    console.log('Received msg<id='+ data_msg_id +'>, doesn\'t match current msg<id='+ current_msg_id +'>. Not updating room.');
  },

  renderMessage: function(data) {
    return "<p> <b>" + data.user + ": </b>" + data.message + "</p>";
  },

  getCurrentMessageId: function() {
    return $('.data-div #message_current_message_id').val();
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
    var user, role, roleStr;
    for(i = 1; i <= data['room_size']; i++) { 
      user = data['seats'][i]['user'];
      role = data['seats'][i]['role'];
      if (role === 'EMPTY_ROLE') {
        roleStr = " (无身份)";
      } else {
        roleStr = ' ('+role+')';
      }
      if (!debug) {
        roleStr = '';
      }
      if (user === 'EMPTY_SEAT_USER') {
        $("#seat-"+i).addClass("btn-success");
        $("#seat-"+i).removeClass("btn-secondary");
        $("#seat-label-"+i).html('空'+roleStr);
      } else {
        $("#seat-"+i).addClass("btn-secondary");
        $("#seat-"+i).removeClass("btn-success");
        $("#seat-label-"+i).html(user+roleStr);
      }
    }
  }
});