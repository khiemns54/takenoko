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
  SUPPORTED_FILE_EXT = [:csv,:yaml,:json, :yml]

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


  mattr_writer :log_folder
  @@log_folder = "tmp/takenoko"

  mattr_accessor :folder_id
  @@folder_id = nil

  require 'takenoko/exporter'
  require 'takenoko/google_client'
  require 'takenoko/attach_helper'
  require 'takenoko/mapping_generator'

  def config
    yield self
  end

  def log_folder
    FileUtils.mkdir_p(@@log_folder) unless File.directory?(@@log_folder)
    @@log_folder
  end
  def google_client
    @@google_client ||= GoogleClient.new(google_cridential_file)
    return @@google_client
  end

  def mapping_config
    MappingGenerator.generate
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
    errors = []
    mapping_config[:tables].each do |table,conf|
      next if conf[:attach_files].blank?
      begin
        download_table_files table
      rescue Exception => e
        errors << e.to_s
      end
    end
    raise errors.join("\n") unless errors.empty?
    
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

  class Railtie < Rails::Railtie
    railtie_name :takenoko

    rake_tasks do
      load "tasks/takenoko.rake"
    end
  end
end