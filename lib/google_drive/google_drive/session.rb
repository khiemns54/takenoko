require "google_drive"
module GoogleDrive
  class Session
    define_method :collection_by_id do |id|
      collection_by_url("https://drive.google.com/#folders/#{id}")
    end
  end
end