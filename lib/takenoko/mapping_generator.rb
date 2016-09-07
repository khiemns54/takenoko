module Takenoko
  module MappingGenerator
    extend self
    @@mapping_conf = nil

    mattr_accessor :allowed_overwrite_fields
    @@allowed_overwrite_fields = [
      :allow_overwrite,
      :truncate_all_data,
      :file_extension,
      :export_file_location,
      :enable_postprocess,
      :postprocess_class,
      :folder_id
    ]

    mattr_accessor :table_filters
    @@table_filters = [
      [:set_worksheet, ->(name, table) {
        table[:worksheet] = name if table[:worksheet].blank? && table[:worksheet_id].blank?
      }],

      [:set_sheetid, ->(name, table){
        raise "#{sheet_id} cannot be blank" unless table[:sheet_id] ||= Takenoko.sheet_id
      }],

      [:set_find_column, ->(name, table){
        table[:find_column] ||= :id
      }],

      [:set_tablename, ->(name, table){
        table[:table_name] = name.pluralize if table[:table_name].blank?
      }],

      [:set_class_name, ->(name, table){
        table[:class_name] ||= table[:table_name] && table[:table_name].singularize.camelize
      }],

      [:overwrite_global_config, ->(name, table){
        allowed_overwrite_fields.each do |f|
          table[f] = Takenoko.public_send(f) unless table.key?(f)
        end
      }],

      [:set_postprocess_class, ->(name, table){
        table[:postprocess_class] ||= table[:class_name]
      }],

      [:check_file_extension, ->(name, table){
        raise "Not support file extension: #{table[:file_extension]}" unless SUPPORTED_FILE_EXT.include?(table[:file_extension])
      }],

      [:set_download_location, ->(name, table){
        table[:download_location] ||= Takenoko.download_location && (Takenoko.download_location + "/" + table[:table_name])
      }],

      [:set_attach_files, ->(name, table){
        if (attach_files = table[:attach_files]).present?
          attach_files = attach_files.map do |col|
            raise "column_name must be set" unless col[:column_name]
            raise "folder_id should be set" unless col[:folder_id] ||= table[:folder_id]
            col[:download_location] ||= col[:download_location].present? ? table[:download_location] + "/" + col[:download_location] : table[:download_location]
          end
        end
      }],
    ]

    def generate
      return @@mapping_conf if Takenoko.always_reload && @@mapping_conf
      @@mapping_conf = base_config
      @@mapping_conf[:tables].each do |name, table|
        table_filters.each do |f|
          f[1].call(name, table)
        end
      end
      return @@mapping_conf
    end

    private

    def check_config
      raise "Must specify mapping_file or sheet_id" unless (Takenoko.mapping_file || Takenoko.sheet_id)
      raise "file not found:#{Takenoko.mapping_file}" if Takenoko.mapping_file && !::File.exist?(Takenoko.mapping_file)
      return true
    end

    def spread_sheet_config
      sheet_conf = HashWithIndifferentAccess.new({tables: {}})
      return sheet_conf unless Takenoko.sheet_id
      Takenoko.google_client.spreadsheet.worksheets.each do |ws|
        next if ws.title.match(/\s*#.*/)
        sheet_conf[:tables][ws.title] = {
          worksheet_id: ws.gid,
          worksheet: ws.title
        }
      end
      sheet_conf
    end

    def mapping_file_config
      return {} unless Takenoko.mapping_file
      file_conf = YAML.load_file(Takenoko.mapping_file).with_indifferent_access
      raise "tables not exists" if file_conf[:tables].blank?
      file_conf
    end

    def base_config
      check_config
      spread_sheet_config
      conf = spread_sheet_config.deep_merge(mapping_file_config).with_indifferent_access
      conf[:tables].compact!
      conf
    end

  end
end
