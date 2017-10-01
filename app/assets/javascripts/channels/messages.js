var debug = true;

App.messages = App.cable.subscriptions.create('MessagesChannel', {
  received: function(data) {
    $("#messages").removeClass('hidden')
    // console.log(data);
    var data_msg_id = data.id;
    var current_msg_id = parseInt(getCurrentMessageId());

    if (data_msg_id === current_msg_id) {
      // First thing update DOM data-div
      previousdata = getCurrentMessageContent();
      setCurrentRoomMessage(data.message)

      // Update seats and Skill Panel
      var gamedata = JSON.parse(data.message);
      var game_started = gamedata['started'] === 'true';
      this.updateSeats(gamedata, game_started);
      this.updateSkillPanel(gamedata);

      var tuple = getCurrentUserSeatNumberAndRole();
      if (tuple) {
        setSkillPanelByRole(tuple.role);
        setIdentityPanelByRole(tuple.role);
      } else {
        hideSkillIdentityPanels();
      }
      return $('#messages').html(this.renderMessage(data));
    }
    console.log('Received msg<id='+ data_msg_id +'>, doesn\'t match current msg<id='+ current_msg_id +'>. Not updating room.');
  },

  renderMessage: function(data) {
    return "<p> <b>" + data.user + ": </b>" + data.message + "</p>";
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
        $("#seat-"+i).removeClass("btn-warning");
        $("#seat-label-"+i).html('空'+roleStr);
      }
      else if (user === getCurrentUserName()) {
        $("#seat-"+i).addClass("btn-warning");
        $("#seat-"+i).removeClass("btn-success");
        $("#seat-"+i).removeClass("btn-outline-success-luwu");
        $("#seat-label-"+i).html(user+roleStr);
      } else {
        $("#seat-"+i).addClass("btn-outline-success-luwu");
        $("#seat-"+i).removeClass("btn-success");
        $("#seat-"+i).removeClass("btn-warning");
        $("#seat-label-"+i).html(user+roleStr);
      }
    }
  },

  updateSkillPanel: function(data) {
    $("#seer-check-info").html(data["seer_check_display"]);
    $("#witch-save-info").html(data["witch_save_display"]);
  }
});

$(document).on('turbolinks:load', function() {
  console.log("In turbolinks:load");
  submitNewMessage();
  updateMessage();
  var panel = document.getElementById('info-panel');
  var skill_panel = document.getElementById('skill-panel');
  var identity_panel = document.getElementById('identity-panel');
  if (!debug) {
    if (panel) {  panel.style.display = 'none'; }
    if (skill_panel) { skill_panel.style.display = 'none'; }
    if (identity_panel) { identity_panel.style.display = 'none'; }
  }
  if (hasMessageContent()) {
    var tuple = getCurrentUserSeatNumberAndRole();
    if (tuple) {
      setSkillPanelByRole(tuple.role);
      setIdentityPanelByRole(tuple.role);
    } else {
      hideSkillIdentityPanels();
    }
  }


});

function lastnightinfo() {
  var panel = document.getElementById('info-panel');
  if (panel.style.display === 'none') {
      panel.style.display = 'block';
  } else {
      panel.style.display = 'none';
  }
}

function identity() {
  var tuple = getCurrentUserSeatNumberAndRole();
  if (tuple) {
    var identity_panel = setIdentityPanelByRole(tuple.role)
    if (identity_panel.style.display === 'none') {
      identity_panel.style.display = 'block';
    } else {
      identity_panel.style.display = 'none';
    }
  } else {
    alert('还没坐下');
  }
}

function useskill() {
  var tuple = getCurrentUserSeatNumberAndRole();
  if (tuple) {
    setSkillPanelByRole(tuple.role);
    var skill_panel = document.getElementById('skill-panel');
    if (skill_panel.style.display === 'none') {
      skill_panel.style.display = 'block';
    } else {
        skill_panel.style.display = 'none';
    }
  }
  else {
    alert('还没坐下');
  }
}



function setIdentityPanelByRole(role) {
  var identity_panel = document.getElementById('identity-panel');
  identity_panel.textContent = mapRoleToName(role);
  return identity_panel;
}

function setSkillPanelByRole(role) {
  document.getElementById('seer-skill-panal').style.display = 'none';
  document.getElementById('witch-skill-panal').style.display = 'none';
  document.getElementById('wolf-skill-panal').style.display = 'none';
  document.getElementById('defender-skill-panal').style.display = 'none';
  document.getElementById('hunter-skill-panal').style.display = 'none';
  document.getElementById('no-skill-panal').style.display = 'none';
  switch(role) {
    case 'seer':
      document.getElementById('seer-skill-panal').style.display = 'block';
      break;
    case 'witch':
      document.getElementById('witch-skill-panal').style.display = 'block';
      break;
    case 'werewolf':
    case 'whitewolf':
      document.getElementById('wolf-skill-panal').style.display = 'block';
      break;
    case 'defender':
      document.getElementById('defender-skill-panal').style.display = 'block';
      break;
    case 'hunter':
      document.getElementById('hunter-skill-panal').style.display = 'block';
      break;
    default:
      document.getElementById('no-skill-panal').style.display = 'block';
  }
}

function mapRoleToName(role) {
    switch(role) {
    case 'seer':
      return '预言家';
    case 'witch':
      return '女巫';
    case 'werewolf':
      return '狼人';
    case 'whitewolf':
      return '白狼王';
    case 'defender':
      return '守卫';
    case 'hunter':
      return '猎人';
    case 'thief':
      return '盗贼';
    case 'elder':
      return '长老';
    case 'villager':
      return '普通村民';
    default:
      return '无身份';
  }
}

function hideSkillIdentityPanels() {
  var skill_panel = document.getElementById('skill-panel');
  var identity_panel = document.getElementById('identity-panel');
  skill_panel.style.display = 'none';
  identity_panel.style.display = 'none';
}

// Helper methods

function hasMessageContent() {
  return $('.data-div #message_current_message_content').length > 0;
}

function getCurrentMessageContent() {
  return $('.data-div #message_current_message_content').val();
}

function getCurrentMessageId() {
  return $('.data-div #message_current_message_id').val();
}

function getCurrentUserId() {
  return $('.data-div #message_this_user_id').val();
}

function getCurrentUserName() {
  return $('.data-div #message_this_user_name').val();
}

function setCurrentRoomMessage(string) {
  return $('.data-div #message_current_message_content').val(string);
}

function getCurrentUserSeatNumberAndRole() {
  var content = getCurrentMessageContent();
  var user_name = getCurrentUserName();
  var hash = JSON.parse(content);
  var room_size = hash['room_size'];
  var seats = hash['seats'];
  for (var i = room_size; i >= 1; i--) {
    if (seats[i]['user'] === user_name) {
      return {
        seat: i,
        role: seats[i]['role']
      }
    }
  }
  return null;
}

// For Debug

function submitNewMessage(){
  $('textarea#message_content').keydown(function(event) {
    if (event.keyCode == 13) {
        $('[data-send="message"]').click();
        $('[data-textarea="message"]').val(" ")
        return false;
     }
  });
}

function updateMessage(){
  $('textarea#message_edit_content').keydown(function(event) {
    if (event.keyCode == 13) {
        $('[data-send="message_edit"]').click();
        $('[data-textarea="message_edit"]').val(" ")
        return false;
     }
  });
}