class Sheet < ActiveRecord::Base
  has_many :lines
  
  attr_protected :id
  
  validates_presence_of :name, :file
  
  after_save :parse_file
  
  mount_uploader :file, SheetUploader
  
  def parse_file
    f = Docx::Document.open(file.url)

    #create lines, assign dates properly, and put the rest into description
    current_date = ''
    f.paragraphs.each do |p|
      if is_date?(p)
        current_date = p
      else
        if !p.blank?
          @line = Line.new({:date => current_date, :description => p, :sheet_id => self.id})
          @line.save
        end
      end
    end
    
    #parse the blob of text in the description for the rest of the data.
    lines.each do |l|
      desc = l.description
      time_cust = ''
      got_cust = false
      i = 0
      while(!got_cust) 
        if desc[i] == ''
          got_cust = true
        else
          time_cust = time_cust + desc[i]
        end
        i++
      end
      l.customer = get_cust_name(time_cust)
      l.time = get_time(time_cust)
      l.description = l.description((i+3)..l.description.length)
      l.save
    end
  end
  
  def is_date?(d)
    test = d.split('/')
    
    dig1 = test[0].to_i
    dig2 = test[1].to_i
    
    !dig1.nil? && !dig2.nil? && dig1 > 1 && dig2 > 1 && dig1 < 13 && dig2 < 32
  end
  
  def get_cust_name(str)
    cust_name = ''
    str.length do |x|
      if str[x] =~ /[[:alpha:]]/
        cust_name = cust_name + str[x]
      end
    end
  end
  
  def get_time(str)
    str.to_f
  end
end
