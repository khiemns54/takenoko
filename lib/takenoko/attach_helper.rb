module Takenoko
  module AttachHelper
    extend self
    def download(table_data)
      errors = []
      table_name = table_data[:table_name]
      takelog = "#{Takenoko.log_folder}/#{table_name}_log.yml"
      log_data = (File.exist?(takelog) && YAML.load_file(takelog)) || {}
      folders = {}
      table_data[:attach_files].each do |col|
        unless (folder_id = col[:folder_id] || table[:folder_id]).present?
          errors << "Folder ID should be set"
          next
        end

        column_name = col[:column_name]
        unless table_data[:header].include?(column_name)
          errors << "Column #{column_name} not found"
          next
        end

        Rails.logger.info "Downloading file form table #{table_name}"
        download_location = col[:download_location]
        FileUtils.mkdir_p(download_location) unless File.directory?(download_location)

        unless ls_files = folders[col[:folder_id]]
          ls_files = folders[col[:folder_id]] = get_drive_files_list Takenoko.google_client.folder_by_id col[:folder_id]
        end

        table_data[:rows].each do |row|
          next if row[column_name].blank?
          file_name = File.basename(row[column_name])
          unless file = ls_files[file_name]
            errors << "Table[#{table_name}] - File: '#{file_name}' not found"
            next
          end
          full_path_name = download_location+"/"+file_name
          log_key = "#{col[:folder_id]}_#{file_name}"
          next if File.exist?(full_path_name) && log_data[log_key].present? && file.modified_date.to_i <= log_data[log_key][:last_modified]

          file.download_to_file(full_path_name)
          Rails.logger.info "Downloaded file: #{full_path_name}"
          log_data[log_key] ||= {}
          log_data[log_key][:last_modified] = file.modified_date.to_i 
        end
      end
      File.open(takelog, 'w') {|f| f.write log_data.to_yaml }
      raise errors.join("\n") unless errors.empty?
      return true
    end

    #Get all file from drive folder
    def get_drive_files_list(folder)
      ls = Hash.new
      page_token = nil
      begin
        (files, page_token) = folder.files("pageToken" => page_token)
        files.each do |f|
          ls[f.original_filename] = f
        end
      end while page_token
      return ls
    end
  end
end