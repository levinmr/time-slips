CarrierWave.configure do |config|
  config.root = Rails.root.join('tmp')
  config.cache_dir = "carrierwave"
  
  config.fog_credentials= { 
    :provider              => "AWS",
    :aws_access_key_id     => "AKIAJCGFRN6LNUF3KSAA",
    :aws_secret_access_key => "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", 
  }
  config.fog_directory = 'Time-slips'
  config.fog_public     = true
  config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}
end
