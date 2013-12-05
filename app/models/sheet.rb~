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
        
        l.description = desc
        l.save
      end
    end
    combine_lines
    new_lines = Line.where("sheet_id = ?", self.id)
    new_lines.each do |l|
      unless l.destroyed?
        l.description = convert_changes(l.description)
        l.save
      end
    end
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
    #split by spaces to get every individual word.  Check each word against the changes listed in the DB.
    old_str_array = str.split(' ')
    
    str_array = []

    old_str_array.length.times do |x|
      if !old_str_array[x].blank?
        str_array << old_str_array[x].downcase
      end
    end

    #reassemble the string
    str_array.length.times do |x|
      #if it's the beginning of the string, or right after punctuation, then capitalize the word.
      word = str_array[x]
      str_array[x] = convert_word(str_array[x])
      if word != str_array[x]
        word = str_array[x]
        if x == 0 || (!str_array[x-1].nil? && (str_array[x-1].split('').last =~ /[.?!]/))
          word[0] = word[0].upcase unless word.nil?
        end
      else
        if x == 0 || (!str_array[x-1].nil? && (str_array[x-1].split('').last =~ /[.?!]/))
          word[0] = word[0].upcase unless word.nil?
        elsif word.length == 2 && (str_array[x].split('').last =~ /[.?!]/)
          word[0] = word[0].upcase unless word.nil?
        end
      end
      str_array[x] = word
    end

    str_array.length.times do |x|
      if str_array[x].downcase == 'notice'
        if !str_array[x+1].nil? && str_array[x+1].downcase == 'of'
          if !str_array[x+2].nil? 
            str_array[x] = 'Notice'
            str_array[x+2] = str_array[x+2][0].upcase + str_array[x+2][1..str_array[x+2].length]
          end
        end
      end 
    end

    str_array.length.times do |x|
      if str_array[x].downcase == 'borough'
        if !str_array[x+1].nil? && str_array[x+1].downcase == 'of'
          if !str_array[x+2].nil? 
            str_array[x] = 'Borough'
            str_array[x+2] = str_array[x+2][0].upcase + str_array[x+2][1..str_array[x+2].length]
          end
        end
      end 
    end

    str_array.length.times do |x|
      if str_array[x].downcase == 'reply'
        if !str_array[x+1].nil? && str_array[x+1].downcase == 'to'
          if !str_array[x+2].nil? && str_array[x+2].downcase == 'new'
            if !str_array[x+3].nil? && str_array[x+3].downcase == 'matter'
              str_array[x] = 'Reply'
              str_array[x+2] = 'New'
              str_array[x+3] = 'Matter'
            end
          end
        end
      end 
    end

    str_array.length.times do |x|
      if str_array[x].downcase == 'interrogatories'
        if !str_array[x+1].nil? && str_array[x+1].downcase == 'and'
          if !str_array[x+2].nil? && str_array[x+2].downcase == 'request'
            if !str_array[x+3].nil? && str_array[x+3].downcase == 'for'
              if !str_array[x+4].nil? && str_array[x+4].downcase == 'production'
                if !str_array[x+5].nil? && str_array[x+5].downcase == 'of'
                  if !str_array[x+6].nil? && str_array[x+6].downcase == 'documents'
                    str_array[x] = 'Interrogatories'
                    str_array[x+2] = 'Request'
                    str_array[x+4] = 'Production'
                    str_array[x+6] = 'Documents'
                  end
                end
              end
            end
          end
        end
      end 
    end

    converted_str = ''
    str_array.length.times do |x|
      #Add a space after each word.
      converted_str = converted_str + str_array[x].to_s + ' '
    end
    converted_str = converted_str.strip
    converted_str
  end
  
  def convert_word(str)
    if str.length > 2 && str.include?('/')
      slash_index = str.index('/')
      new_str = convert_word(str[0..(slash_index-1)]) + '/' + convert_word(str[(slash_index+1)..str.length])
    else
      punctuation = (str.split('').last =~ /[.?!;]/ ? str.split('').last : nil)
      new_str = (punctuation.nil? ? str.downcase : str[0..-2].downcase)
      possessive = (new_str.include?("'s") ? true : false)
      new_str = new_str[0..-3] if possessive == true
      @changes = Change.all
      @changes.each do |c|
        if new_str == c.abbrev.downcase
          new_str = c.name
          break 
        end
      end
      new_str = new_str + (possessive == true ? "'s" : "") + (punctuation.nil? ? "" : punctuation)
    end
    new_str
  end
  
  def combine_lines
    dates = lines.uniq{ |l| l.date }.collect{ |l| l.date}
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
