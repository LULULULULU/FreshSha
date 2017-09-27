class Seat
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :number, :user, :role, :status 
end