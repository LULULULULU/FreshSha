var debug = true;

App.messages = App.cable.subscriptions.create('MessagesChannel', {
  received: function(data) {
    $("#messages").removeClass('hidden')
    // console.log(data);
    var data_msg_id = data.id;
    var current_msg_id = parseInt(this.getCurrentMessageId());

    if (data_msg_id === current_msg_id) {
      // First thing update DOM data-div
      previousdata = this.getCurrentRoomMessage();
      this.setCurrentRoomMessage(data.message)

      // Update seats and Skill Panel
      var gamedata = JSON.parse(data.message);
      var game_started = gamedata['started'] === 'true';
      this.updateSeats(gamedata, game_started);
      this.updateSkillPanel(gamedata);

      var tuple = getCurrentUserSeatNumberAndRole();
      if (tuple) {
        setSkillPanelByRole(tuple.role);
      }


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

  updateSeats: function(data, game_started) {
    var user, role, roleStr = '';
    for(i = 1; i <= data['room_size']; i++) {
      user = data['seats'][i]['user'];
      role = data['seats'][i]['role'];

      if (debug) {
        if (role === 'EMPTY_ROLE') {
          roleStr = " (无身份)";
        } else {
          roleStr = ' ('+role+')';
        }
      }
      if (game_started) {
        $("#seat-"+i).addClass("disabled");
        $("#seats-panel").addClass("shrink");
        $("#topic-panel-current-turn-h").text(data['turn_display']);
      } else {
        $("#seat-"+i).removeClass("disabled");
        $("#seats-panel").removeClass("shrink");
        $("#topic-panel-current-turn-h").text("游戏尚未开始");
      }
      $("#seat-"+i).prop("disabled", game_started);
      if (user === 'EMPTY_SEAT_USER') {
        $("#seat-"+i).addClass("btn-success");
        $("#seat-"+i).removeClass("btn-outline-success-luwu");
        $("#seat-label-"+i).html('空'+roleStr);
      } else {
        $("#seat-"+i).addClass("btn-outline-success-luwu");
        $("#seat-"+i).removeClass("btn-success");
        $("#seat-label-"+i).html(user+roleStr);
      }
    }
  },

  updateSkillPanel: function(data) {
    $("#seer-check-info").html(data["seer_check_display"]);
    $("#witch-save-info").html(data["witch_save_display"]);
  }
});