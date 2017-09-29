class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  helper_method :current_user, :logged_in?

  # Rules constants
  FIRST_NIGHT_SAVE = 'FirstNightSave'
  NOT_SELF_SAVE = 'CannotSaveSelf'
  CAN_SELF_SAVE = 'CanSaveSelf'

  CURE_POISON_TOGETHER = 'CanUseCurePoisonSameNight'
  NOT_CURE_POISON_TOGETHER = 'CannotUseCurePoisonSameNight'

  GUARD_CURE_IS_DEAD = 'GuardAndCuredIsDead'
  GUARD_CURE_IS_ALIVE = 'GuardAndCuredIsAlive'

  PICK_WOLF = 'MustPickWerewolf'
  ALL_PICK = 'AllPick'

  # Role constants
  SEER = "seer"
  WITCH = "witch"
  HUNTER = "hunter"
  DEFENDER = "defender"
  THIEF = "thief"
  ELDER = "elder"
  VILLAGER = "villager"
  WHITEWOLF = "whitewolf"
  WEREWOLF = "werewolf"

  # Additional turn string
  WOLF = "wolf"
  SEER_CHECK_TURN = "seer_check"
  SEER_END_TURN = "seer_end"
  DAY_TIME = "day_time"

  GAME_TURN = [THIEF, DEFENDER, SEER_CHECK_TURN, SEER_END_TURN, WOLF, WITCH, DAY_TIME]
  GAME_TURN_DISPLAY_MAP = {
    THIEF => "盗贼请睁眼", DEFENDER => "守卫请睁眼",
    SEER_CHECK_TURN => "预言家请睁眼", SEER_END_TURN => "预言家结束",
    WOLF => "狼人请睁眼", WITCH => "女巫请睁眼", DAY_TIME => "天亮了"
  }

  # Skills
  WITCH_KILL = "witch_kill"
  WITCH_SAVE = "witch_save"
  DEFENDER_GUARD = "defender_guard"
  WOLF_KILL = "wolf_kill"
  SEER_CHECK = "seer_check"

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end


  protected

  def authenticate_user!
    redirect_to root_path unless logged_in?
  end
end
