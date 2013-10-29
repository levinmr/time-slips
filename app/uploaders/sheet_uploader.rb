# encoding: utf-8

class SheetUploader < CarrierWave::Uploader::Base  
  storage :fog
  
  def extension_white_list
    %w(docx)
  end

end
