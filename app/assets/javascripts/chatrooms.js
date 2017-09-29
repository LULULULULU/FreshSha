$(document).on('turbolinks:load', function() {
  submitNewMessage();
  updateMessage();
  var gamedata = 'soemthing';
  var panel = document.getElementById('info-panel');
  var skill_panel = document.getElementById('skill-panel');
  var identity_panel = document.getElementById('identity-panel');
  // if (panel) {  panel.style.display = 'none'; }
  if (skill_panel) { skill_panel.style.display = 'none'; }
  if (identity_panel) { identity_panel.style.display = 'none'; }
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

function updateMessage(){
  $('textarea#message_edit_content').keydown(function(event) {
    if (event.keyCode == 13) {
        $('[data-send="message_edit"]').click();
        $('[data-textarea="message_edit"]').val(" ")
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

function identity() {
  var tuple = getCurrentUserSeatNumberAndRole();
  if (tuple) {
    var identity_panel = document.getElementById('identity-panel');
    identity_panel.textContent = mapRoleToName(tuple.role);
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

function getCurrentUserName() {
  return $('.data-div #message_this_user_name').val();
}

function getCurrentMessageContent() {
  return $('.data-div #message_current_message_content').val();
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

