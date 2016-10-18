module Takenoko
  module AttachHelper
    extend self
    def download(table_data)
      errors = []
      table_name = table_data[:table_name]
      takelog = "#{Takenoko.log_folder}/#{table_name}_log.yml"
      log_data = (File.exist?(takelog) && YAML.load_file(takelog)) || {}

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
        folder = Takenoko.google_client.folder_by_id col[:folder_id]

        table_data[:rows].each do |row|
          next if row[column_name].blank?
          file_name = File.basename(row[column_name])
          unless file = folder.file_by_title(file_name)
            errors << "Table[#{table_name}] - File: '#{file_name}' not found"
            next
          end
          full_path_name = download_location+"/"+file_name
          find_col = row[table_data[:find_column]]
          next if File.exist?(full_path_name) && log_data[find_col].present? && file.modified_date.to_i <= log_data[find_col][:last_modified]

          file.download_to_file(full_path_name)
          Rails.logger.info "Downloaded file: #{full_path_name}"
          log_data[find_col] ||= {}
          log_data[find_col][:last_modified] = file.modified_date.to_i 
        end
      end
      File.open(takelog, 'w') {|f| f.write log_data.to_yaml }
      raise errors.join("\n") unless errors.empty?
      return true
    end
  end
end