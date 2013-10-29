class Line < ActiveRecord::Base
  belongs_to :sheet
  belongs_to :client
  
  attr_protected :id
end
