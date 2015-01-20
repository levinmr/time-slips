class Sheet < ActiveRecord::Base
  has_many :lines, dependent: :destroy

  attr_protected :id

  validates_presence_of :name, :file

  mount_uploader :file, SheetUploader

  def parse_file
    @changes = Change.all
    # delete all existing lines for the sheet (since we're replacing them)
    Line.delete_all("sheet_id = #{id} or sheet_id is null")

    f = Docx::Document.open(open(
      file.to_s, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE))

    # create lines, assign dates properly, and put the rest into description
    current_date = ''
    f.paragraphs.each do |p|
      para = p.to_s
      if date?(para)
        current_date = Date.parse convert_date(para)
        current_date.change(year: 1.month.ago.year)
      else
        unless para.blank?
          @line = Line.new(date: current_date,
                           description: para,
                           sheet_id: id)
          @line.save
        end
      end
    end

    # parse the blob of text in the description for the rest of the data.
    new_lines = Line.where(sheet_id: id).select { |l| !l.destroyed? }
    new_lines.each do |l|
      l.description = get_time_and_client_return_description(l)
      l.save
    end
    combine_lines
    logger.info('Lines combined!')
    new_lines = Line.where(sheet_id: id).select { |l| !l.destroyed? }
    logger.info("New number of lines: #{new_lines.length}")
    new_lines.each_with_index do |l, i|
      logger.info("Line Number #{i} started")
      l.description = convert_changes(l.description.downcase)
      l.save
    end
    logger.info('All Lines Converted!')
  end

  private

  def get_time_and_client_return_description(l)
    desc = l.description
    desc = desc.gsub(/\u2013|\u2014|\u2015/, '-')

    first_dash = (desc.index('-').nil? ? 0 : desc.index('-'))
    time_cust = desc[0..(first_dash - 1)] || ''
    desc = desc[(first_dash + 1)..desc.length]
    second_dash = desc.index('-')
    desc = desc[(second_dash + 1)] if second_dash && second_dash < 2

    cust_name = '%' + get_cust_name(time_cust).downcase + '%'
    logger.info("client.abbrev LIKE #{cust_name}")
    l.client = Client.where('lower(abbrev) like ?', cust_name).first
    if l.client.nil?
      c = Client.create(abbrev: get_cust_name(time_cust).titleize,
                        name: get_cust_name(time_cust).titleize)
      l.client_id = c.id
    end
    # parse the hours worked
    l.time = get_time(time_cust)
    l.save

    desc.strip
  end

  def date?(d)
    test = d.split('/')
    dig1 = test[0].to_i
    dig2 = test[1].to_i

    dig1 && dig2 && dig1 > 0 && dig2 > 0 && dig1 < 13 && dig2 < 32
  end

  def convert_date(d)
    test = d.split('/')
    "#{test[0]}/#{test[1]}" # ignores the year if it was included.
  end

  def get_cust_name(str)
    arr = str.split('')
    cust_name = ''
    arr.length.times do |x|
      arr[x] =~ /[[:alpha:]]/ ? break : cust_name = str[(x + 1)..str.length]
    end
    cust_name.strip
  end

  def get_time(str)
    str.to_f
  end

  # params: lowercase string of words and punctuation
  # return: same string with changes replaced and proper capitalization
  def convert_changes(str)
    # Split by spaces to get every individual word.
    # Check each word against the changes listed in the DB.
    str_array = str.split(' ').select { |x| !x.blank? }

    # Convert Words as needed.
    str_array.map do |x|
      if x.include?('/')
        word_splitter(x, '/')
      elsif x.include?('-')
        word_splitter(x, '-')
      else
        convert_word(x)
      end
    end

    str_array.length.times do |x|
      if str_array[x].downcase == 'notice' &&
        (str_array[x + 1] && str_array[x + 1].downcase == 'of') &&
        str_array[x + 2]

        str_array[x] = 'Notice'
        str_array[x + 2] = str_array[x + 2].capitalize
      end
    end

    str_array.length.times do |x|
      if str_array[x].downcase == 'motion' &&
        (str_array[x + 1] && str_array[x + 1].downcase == 'to') &&
        str_array[x + 2]

        str_array[x] = 'Motion'
        str_array[x + 2] = str_array[x + 2].capitalize
      end
    end

    str_array.length.times do |x|
      if str_array[x].downcase == 'borough' &&
        (str_array[x + 1] && str_array[x + 1].downcase == 'of') &&
        str_array[x + 2]

        str_array[x] = 'Borough'
        str_array[x + 2] = str_array[x + 2].capitalize
      end
    end

    str_array.length.times do |x|
      if str_array[x].downcase == 'reply' &&
        (str_array[x + 1] && str_array[x + 1].downcase == 'to') &&
        (str_array[x + 2] && str_array[x + 2].downcase == 'new') &&
        (str_array[x + 3] && str_array[x + 3].downcase == 'matter')

        str_array[x] = 'Reply'
        str_array[x + 2] = 'New'
        str_array[x + 3] = 'Matter'
      end
    end

    str_array.length.times do |x|
      if str_array[x].downcase == 'interrogatories'
        (str_array[x + 1] && str_array[x + 1].downcase == 'and') &&
        (str_array[x + 2] && str_array[x + 2].downcase == 'request') &&
        (str_array[x + 3] && str_array[x + 3].downcase == 'for') &&
        (str_array[x + 4] && str_array[x + 4].downcase == 'production') &&
        (str_array[x + 5] && str_array[x + 5].downcase == 'of') &&
        (str_array[x + 6] && str_array[x + 6].downcase == 'documents')

        str_array[x] = 'Interrogatories'
        str_array[x + 2] = 'Request'
        str_array[x + 4] = 'Production'
        str_array[x + 6] = 'Documents'
      end
    end

    if str_array.include?('fof/col') || str_array.include?('fof/col;')
      str_array.length.times do |x|
        if str_array[x] == 'fof/col' || str_array[x] == 'fof/col;'
          before = str_array[0..x - 1]
          after = str_array[x + 1..str_array.length]
          semi = true if str_array[x][str_array[x].length - 1] == ';'
          new_array = ['Findings', 'of', 'Fact', 'and', 'Conclusions', 'of',
                       'Law' + (semi == true ? ';' : '')]
          str_array = before + new_array + after
          break_it = true
        end
        break if break_it == true
      end
    end

    # Capitalize properly
    str_array.length.times do |x|
      # If it's the beginning of the string, or right after punctuation,
      # then capitalize the word.
      if x == 0 || (str_array[x - 1] &&
        (str_array[x - 1].split('').last =~ /[.?!]/))
        str_array[x] = str_array[x].capitalize
      elsif str_array[x].length == 2 && (str_array[x].split('').last =~ /[.?!]/)
        str_array[x] = str_array[x].capitalize
      end
    end

    converted_str = "#{str_array.blank? ? '' : str_array.join(' ')}"
    converted_str.strip
  end

  def convert_word(str)
    punctuation = str.split('').last =~ /[.?!;,]/ ? str.split('').last : nil
    new_str = (punctuation.nil? ? str : str[0..-2])
    possessive = (new_str.include?("'s") ? true : false)
    new_str = new_str[0..-3] if possessive == true
    @changes.each do |c|
      if new_str.casecmp(c.abbrev) == 0
        new_str = c.name
        break
      end
    end
    new_str = new_str + (possessive == true ? "'s" : '') +
      (punctuation.nil? ? '' : punctuation)
  end

  def word_splitter(str, split_char)
    if str.length > 2
      split_index = str.index(split_char)
      if split_index == 0
        "/ #{convert_word(str[1..str.length])}"
      elsif split_index == str.length
        "#{convert_word(str[0..str.length - 1])} /"
      else
        convert_word(str[0..(split_index - 1)]) + split_char +
          convert_word(str[(split_index + 1)..str.length])
      end
    else
      convert_word(str)
    end
  end

  def combine_lines
    dates = lines.uniq { |l| l.date }.map { |l| l.date }
    dates.each do |date|
      customers = lines.select { |l| l.date == date }
                       .uniq   { |c| c.client_id }
                       .map    { |c| c.client_id }
      customers.each do |cust|
        need_combined =
          lines.select { |l| l.date == date && l.client_id == cust }
        if need_combined.size > 1
          parent = need_combined.first
          need_combined.each do |x|
            if x.id != parent.id && !x.destroyed?
              parent.time = parent.time + x.time
              parent.description = parent.description + '; ' + x.description
              x.delete
            end
          end
          parent.save
        end
      end
    end
  end
end
