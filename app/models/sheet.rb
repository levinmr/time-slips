class Sheet < ActiveRecord::Base
  has_many :lines, :dependent => :destroy
  
  attr_protected :id
  
  validates_presence_of :name, :file
  
  mount_uploader :file, SheetUploader
  
  def parse_file
    l = Line.where("sheet_id = ? or sheet_id is null", self.id)
    l.each do |line|
      line.destroy
    end
    
    f = Docx::Document.open(open(file.to_s, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))

    #create lines, assign dates properly, and put the rest into description
    current_date = ''
    f.paragraphs.each do |p|
      para = p.to_s
      if is_date?(para)
        current_date = Date.parse para
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
    combine_lines
  end
  
  def get_time_and_client_return_description(l)
    desc = l.description 
    desc = desc.gsub(/\u2013|\u2014/, "-")
    time_cust = ''
    
    first_dash = (desc.index('-').nil? ? 0 : desc.index('-'))
    time_cust = desc[0..(first_dash-1)]
    desc = desc[(first_dash+1)..desc.length]
    second_dash = desc.index('-')
    if !second_dash.nil? && second_dash < 2
      desc = desc[(second_dash+1)]
    end
  
    cust_name = '%' + get_cust_name(time_cust).downcase + '%'
    logger.info("client.abbrev LIKE #{cust_name}")
    l.client = Client.where('lower(abbrev) like ?', cust_name).first
    if l.client.nil?
      c = Client.new({:abbrev => get_cust_name(time_cust).titleize, :name => get_cust_name(time_cust).titleize})
      c.save
      l.client_id = c.id
    end
    #parse the hours worked
    l.time = get_time(time_cust)
    l.save
    
    desc = desc.strip
    desc
  end
  
  def is_date?(d)
    test = d.split('/')
    
    dig1 = test[0].to_i
    dig2 = test[1].to_i
    
    !dig1.nil? && !dig2.nil? && dig1 > 0 && dig2 > 0 && dig1 < 13 && dig2 < 32
  end
  
  def get_cust_name(str)
    arr = str.split('')
    cust_name = ''
    arr.length.times do |x|
      if arr[x] =~ /[[:alpha:]]/
        break
      else 
        cust_name = str[(x+1)..str.length]
      end
    end
    cust_name = cust_name.strip
    cust_name
  end
  
  def get_time(str)
    str.to_f
  end
  
  def convert_changes(str)
    converted_str = ''
    
    #split by spaces to get every individual word.  Check each word against the changes listed in the DB.
    str_array = str.split(' ')
    
    #reassemble the string
    str_array.length.times do |x|
      #if it's the beginning of the string, or right after punctuation, then capitalize the word.
      str_array[x] = str_array[x].downcase
      word = str_array[x]
      str_array[x] = convert_word(str_array[x])
      if word != str_array[x]
        word = str_array[x]
        if x == 0 || (!str_array[x-1].nil? && !(str_array[x-1].split(//).last =~ /[a-zA-Z0-9]/))
          word[0] = word[0].upcase unless word.nil?
        end
      else
        if x == 0 || (!str_array[x-1].nil? && !(str_array[x-1].split(//).last =~ /[a-zA-Z0-9;' ]/))
          word = word.titleize if !word.nil?
        elsif word.length == 2 && !(str_array[x].split(//).last =~ /[a-zA-Z0-9;' ]/)
          word = word.titleize if !word.nil?
        end
      end
      #Add a space after each word.
      converted_str = converted_str + word.to_s + ' '
    end
    converted_str = converted_str.strip
    converted_str
  end
  
  def convert_word(str)
    punctuation = (str.split('').last =~ /[[:alpha:]]/ ? nil : str.split('').last)
    punctuation = nil if punctuation == '/' || punctuation == ':'
    new_str = (punctuation.nil? ? str : str[0..-1])
    stripped_str = new_str.downcase if !new_str.nil?
    @changes = Change.all
    @changes.each do |c|
      if stripped_str == c.abbrev.downcase
        new_str = c.name + (punctuation.nil? ? '' : punctuation)
        break 
      end
    end
    new_str
  end
  
  def combine_lines
    dates = lines.uniq{ |l| l.date }.collect{ |l| l.date}
    need_deleted = []
    dates.each do |date|
      current_lines = lines.select{ |l| l.date == date}
      customers = current_lines.uniq{ |c| c.client_id}.collect{ |c| c.client_id}
      customers.each do |cust|
        need_combined = lines.select{ |l| l.date == date && l.client_id == cust}
        if need_combined.size > 1
          parent = need_combined.first
          need_combined.each do |x|
            if x.id != parent.id && !x.destroyed?
              parent.time = parent.time + x.time
              parent.description = parent.description + "; " + x.description
              x.destroy
            end
          end
          parent.save
        end
      end
    end
  end
end
