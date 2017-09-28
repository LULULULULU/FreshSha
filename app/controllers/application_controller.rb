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
  WOLF = 'wolf' # Not a real role
  WHITEWOLF = "whitewolf"
  WEREWOLF = "werewolf"


  GAME_TURN = [THIEF, DEFENDER, SEER, WOLF, WITCH]


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
