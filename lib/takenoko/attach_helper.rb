module Takenoko
  module AttachHelper
    extend self
    def download(table_data)
      table_data[:attach_files].each do |col|
        raise "Folder ID should be set" unless (folder_id = col[:folder_id] || table[:folder_id]).present?
        column_name = col[:column_name]
        raise "Column #{column_name} not found" unless table_data[:header].include?(column_name)
        Rails.logger.info "Downloading file form table #{table_data[:table_name]}"
        download_location = col[:download_location]
        FileUtils.mkdir_p(download_location) unless File.directory?(download_location)
        folder = Takenoko.google_client.folder_by_id col[:folder_id]

        table_data[:rows].each do |row|
          next if row[column_name].blank?
          file_name = File.basename(row[column_name])
          raise "File: '#{file_name}' not found" unless file = folder.file_by_title(file_name)
          full_path_name = download_location+"/"+file_name
          file.download_to_file(full_path_name)
          Rails.logger.info "Downloaded file: #{full_path_name}"
        end
      end
      return true
    end
  end
end