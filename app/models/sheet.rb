class Sheet < ActiveRecord::Base
  has_many :lines
  
  attr_protected :id
  
  validates_presence_of :name, :file
  
  mount_uploader :file, SheetUploader
  
  def parse_file
    lines.each do |l|
      l.destroy
    end
    
    f = Docx::Document.open(open(file.to_s, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))

    #create lines, assign dates properly, and put the rest into description
    current_date = ''
    f.paragraphs.each do |p|
      para = p.to_s
      if is_date?(para)
        current_date = para
      else
        if !para.blank?
          @line = Line.new({:date => current_date, :description => para, :sheet_id => self.id})
          @line.save
        end
      end
    end
    
    #parse the blob of text in the description for the rest of the data.
    new_lines = Line.where("sheet_id = ?", self.id)
    new_lines.each do |l|
      unless l.destroyed?
        desc = get_time_and_client_return_description(l)
        
        l.description = convert_changes(desc)
        l.save
      end
    end
  end
  
  def get_time_and_client_return_description(l)
    desc = l.description  
    time_cust = ''
    
    first_space = desc.index(" ")
    if desc[first_space+1] != '-'
      time_cust = desc[0..first_space]
      desc = desc[(first_space + 1)..desc.length]
      first_space = desc.index(" ")
    end
    time_cust = time_cust + desc[0..first_space-1]
  
    cust_name = '%' + get_cust_name(time_cust).downcase + '%'
    l.client = Client.where('lower(abbrev) like ?', cust_name).first
    #parse the hours worked
    l.time = get_time(time_cust)
    l.save
    
    #remove the part we just parsed, and the spacers
    desc = desc[(time_cust.length + 1)..desc.length]
    second_space = desc.index(" ")
    desc = desc[(second_space + 1)..desc.length]
    
    desc
  end
  
  def is_date?(d)
    test = d.split('/')
    
    dig1 = test[0].to_i
    dig2 = test[1].to_i
    
    !dig1.nil? && !dig2.nil? && dig1 > 1 && dig2 > 1 && dig1 < 13 && dig2 < 32
  end
  
  def get_cust_name(str)
    cust_name = ''
    str_array = str.split(//)
    str_array.length.times do |x|
      if str_array[x] =~ /[[:alpha:]]/
        cust_name = cust_name + str_array[x]
      end
    end
    cust_name.to_s
  end
  
  def get_time(str)
    str.to_f
  end
  
  def convert_changes(str)
    converted_str = ''
    
    #split by spaces to get every individual word.  Check each word against the changes listed in the DB.
    str_array = str.split(' ')
    str_array.length.times do |x|
      str_array[x] = convert_word(str_array[x])
    end
    
    #reassemble the string
    str_array.length.times do |x|
      #if it's the beginning of the string, or right after punctuation, then capitalize the word.
      word = str_array[x]
      if x == 0 && !str_array[x-1].nil? && (str_array[x-1].split(//).last =~ /[[:alpha:]]/)
        word.titleize if !word.nil?
      else
        word.downcase if !word.nil?
      end
      #Add a space after each word.
      converted_str = converted_str + word.to_s + ' '
    end
    converted_str
  end
  
  def convert_word(str)
    punctuation = (str.split('').last =~ /[[:alpha:]]/ ? nil : str.split('').last)
    punctuation = nil if punctuation == '/' || punctuation == ':'
    new_str = (punctuation.nil? ? str : str[0..-1])
    new_str = new_str.downcase if !new_str.nil?
    @changes = Change.all
    @changes.each do |c|
      if new_str == c.abbrev.downcase
        new_str = c.name.downcase + (punctuation.nil? ? '' : punctuation)
        break 
      end
    end
    new_str
  end
end
