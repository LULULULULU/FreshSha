class Skill
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :witch_kill, :witch_save, :defender_guard, :wolf_kill, :seer_check
end