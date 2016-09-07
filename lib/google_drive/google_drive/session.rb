require "google_drive"
module GoogleDrive
  class Session
    define_method :collection_by_id do |id|
      raise "Collection #{id} not found" unless collection = files.select do |f|
        (f.is_a? GoogleDrive::Collection) && f.id == id
      end.first
      collection
    end
  end
end