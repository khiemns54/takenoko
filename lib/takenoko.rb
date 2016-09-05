require 'rails'
require 'google/apis/drive_v2'
require 'google_drive'
require 'google_drive/google_drive'

module Takenoko 
  extend self
  mattr_accessor :google_cridential_file
  @@google_cridential_file = nil

  mattr_accessor :mapping_file
  @@mapping_file = false

  @@google_client = nil
  @@mapping_config = nil

  mattr_accessor :file_extension
  @@file_extension = :csv
  SUPPORTED_FILE_EXT = [:csv,:yaml,:json]

  mattr_accessor :export_file_location
  @@export_file_location = "db/spreadsheet"

  mattr_accessor :truncate_all_data
  @@truncate_all_data = false

  mattr_accessor :allow_overwrite
  @@allow_overwrite = false

  require 'takenoko/exporter'
  require 'takenoko/google_client'

  def config
    yield self
  end

  def import
    check_config
  end

  def google_client
    @@google_client ||= GoogleClient.new(@@google_cridential_file)
    return @@google_client
  end

  def check_config
    raise "google_cridential_file setting cannot be nil" unless @@google_cridential_file
    raise "file not found:#{@@google_cridential_file}" unless ::File.exist?(@@google_cridential_file)
    raise "mapping_file cannot be nil" unless @@mapping_file
    raise "file not found:#{@@mapping_file}" unless ::File.exist?(@@mapping_file)
    return true
  end

  def mapping_config
    return @@mapping_config if @@mapping_config
    conf = YAML.load_file(@@mapping_file).with_indifferent_access
    raise "tables not exists" if conf[:tables].blank?
    conf[:tables].each do |t, v|
      table = conf[:tables][t]
      raise "Table config cannot be nil" unless table
      [:sheet_id, :worksheet_id, :columns_mapping].each do |f|
        raise "#{f} cannot be blank" if table[f].blank?
      end
      table[:find_column] = table[:find_column] || :id
      table_name = table[:table_name] = t if table[:table_name].blank?
      table[:class_name] = table[:class_name] || (table_name && table_name.singularize.camelize) || table[:table_name].singularize.camelize
      unless table[:columns_mapping].key?(table[:find_column])
        if(table[:find_column] == :id)
          table[:columns_mapping] = {id: nil}.merge!(table[:columns_mapping])
        else
          table[:columns_mapping][table[:find_column]] = nil 
        end
      end
      table[:columns_mapping].each do |s_col,db_col|
        table[:columns_mapping][s_col] = s_col unless db_col 
      end

      table[:header] = table[:columns_mapping].keys

      [:allow_overwrite,:truncate_all_data, :file_extension, :export_file_location].each do |f|
        table[f] = table[f] || class_variable_get("@@" + f.to_s)
      end

      raise "Not support file extension: #{table[:file_extension]}" unless SUPPORTED_FILE_EXT.include?(table[:file_extension])
    end
    @@mapping_config = conf
  end

  def table_config(table_name)
    raise "#{table_name} config not exists" unless conf = mapping_config[:tables][table_name]
    return conf
  end

  (SUPPORTED_FILE_EXT.clone << :db).each do |output|
    define_method "table_to_#{output}" do | table_name |
      data = google_client.get_table(table_name)
      Exporter.public_send("table_to_#{output}",data)
    end

    define_method "all_to_#{output}" do
      mapping_config[:tables].each do |table,conf|
        Takenoko.public_send("table_to_#{output}",table)
      end
    end
  end

  class Railtie < Rails::Railtie
    railtie_name :takenoko

    rake_tasks do
      load "tasks/takenoko.rake"
    end
  end
end