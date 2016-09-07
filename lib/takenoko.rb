require 'rails'
require 'google_drive'
require 'google_drive/google_drive'
require 'google_drive/google_drive/session'

module Takenoko 
  extend self
  mattr_accessor :google_cridential_file
  @@google_cridential_file = nil

  mattr_accessor :personal_cridential_file
  @@personal_cridential_file = "config/my_cridential.json"

  mattr_accessor :mapping_file
  @@mapping_file = false

  mattr_accessor :always_reload
  @@always_reload = true

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
  @@allow_overwrite = true

  mattr_accessor :sheet_id
  @@sheet_id = nil

  mattr_accessor :enable_postprocess
  @@enable_postprocess = false

  mattr_accessor :postprocess_class
  @@postprocess_class = nil

  mattr_accessor :download_location
  @@download_location = "tmp/attach_files"

  mattr_accessor :folder_id
  @@folder_id = nil


  require 'takenoko/exporter'
  require 'takenoko/google_client'
  require 'takenoko/attach_helper'

  def config
    yield self
  end

  def google_client
    @@google_client ||= GoogleClient.new(@@google_cridential_file)
    return @@google_client
  end

  def check_config
    raise "Must specify mapping_file or sheet_id" unless (@@mapping_file || @@sheet_id)
    raise "file not found:#{@@mapping_file}" if @@mapping_file && !::File.exist?(@@mapping_file)
    return true
  end

  def mapping_config
    (@@always_reload && generate_base_config) || @@mapping_config || generate_base_config
  end

  def table_config(table_name)
    raise "#{table_name} config not exists" unless conf = mapping_config[:tables][table_name]
    return conf
  end

  def download_attached_files(table_name)
    table_data = google_client.get_table(table_name)
    return false unless table_data[:attach_files].present?
    return AttachHelper.download table_data
  end

  def download_table_files(table_name)
    table_data = google_client.get_table(table_name)
    raise "attach_files not set" unless table_data[:attach_files].present?
    AttachHelper.download table_data
  end

  def download_all_files
    mapping_config[:tables].each do |table,conf|
      next if conf[:attach_files].blank?
      download_table_files table
    end
    return true
  end

  (SUPPORTED_FILE_EXT.clone << [:db,:file]).flatten!.each do |output|
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

  def generate_base_config
    return unless check_config

    conf = HashWithIndifferentAccess.new

    if @@sheet_id
      sheet_conf = HashWithIndifferentAccess.new({tables: {}})
      google_client.spreadsheet.worksheets.each do |ws|
        next if ws.title.match(/\s*#.*/)
        sheet_conf[:tables][ws.title] = {
          worksheet_id: ws.gid,
          worksheet: ws.title
        }
      end
      conf.deep_merge!(sheet_conf)
    end

    if @@mapping_file
      file_conf = YAML.load_file(@@mapping_file).with_indifferent_access
      raise "tables not exists" if file_conf[:tables].blank?
      conf.deep_merge!(file_conf)
    end

    conf[:tables].compact!
    conf[:tables].each do |t, v|
      unless conf[:tables][t]
        conf[:tables][t] = Hash.new
      end
      table = conf[:tables][t]
      raise "#{sheet_id} cannot be blank" unless table[:sheet_id] ||= @@sheet_id
      table[:worksheet] = t if table[:worksheet].blank? && table[:worksheet_id].blank?
      table[:find_column] = table[:find_column] || :id
      table_name = table[:table_name] = t.pluralize if table[:table_name].blank?
      table[:class_name] = table[:class_name] || (table_name && table_name.singularize.camelize) || table[:table_name].singularize.camelize
      [
        :allow_overwrite,
        :truncate_all_data,
        :file_extension,
        :export_file_location,
        :enable_postprocess,
        :postprocess_class,
        :folder_id
      ].each do |f|
        table[f] = class_variable_get("@@" + f.to_s) unless table.key?(f)
      end

      if table[:enable_postprocess] && table[:postprocess_class].blank?
        table[:postprocess_class] = table[:class_name]
      end

      raise "Not support file extension: #{table[:file_extension]}" unless SUPPORTED_FILE_EXT.include?(table[:file_extension])

      table[:download_location] = table[:download_location] || (@@download_location  && (@@download_location +"/"+table[:table_name]))
      if attach_files = table[:attach_files].present?
        attach_files = table[:attach_files]
        attach_files = attach_files.map do |col|
          raise "column_name must be set" unless col[:column_name]
          col[:download_location] = col[:download_location].present? ? table[:download_location] + "/" + col[:download_location] : table[:download_location]
          raise "folder_id should be set" unless col[:folder_id] = col[:folder_id] || table[:folder_id]
        end
      end
    end
    @@mapping_config = conf
  end
  alias reload_config! generate_base_config

  class Railtie < Rails::Railtie
    railtie_name :takenoko

    rake_tasks do
      load "tasks/takenoko.rake"
    end
  end
end