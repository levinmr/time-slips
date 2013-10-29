class Client < ActiveRecord::Base
  has_many :lines
  
  attr_protected :id
end
