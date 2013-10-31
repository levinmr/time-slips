class Line < ActiveRecord::Base
  belongs_to :sheet
  belongs_to :client
  
  attr_protected :id
  
  default_scope order('date ASC')
end
