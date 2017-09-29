require 'messages_helper'
require 'logger'

class Skill
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :witch_kill, :witch_save, :defender_guard, :wolf_kill, :seer_check, :seer_end
end