class Chatroom < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_many :users, through: :messages
  validates :topic, presence: true, uniqueness: true, case_sensitive: false
  before_validation :sanitize, :slugify

  attr_accessor :cure_rules, :poison_rule, :guard_rule, :thief_rule, :seer, :witch, :hunter, :defender, :elder, :thief, :villager, :werewolf, :whitewolf

  def to_param
    self.slug
  end

  def slugify
    self.slug = self.topic.downcase.gsub(" ", "-")
  end

  def sanitize
    self.topic = self.topic.strip
  end
end
