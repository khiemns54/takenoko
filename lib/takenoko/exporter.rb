require "takenoko"
module Takenoko
  module Exporter
    extend self
    def to_db(table)
      config = table[:config]
      tb_class = Object.const_get("::"+config[:class_name])
      raise "Class not found:#{table[:class_name]}" unless tb_class <= ActiveRecord::Base
      tb_class.destroy_all if config[:truncate_all_data]
      table[:rows].each do |r|
        if db_r = tb_class.find_by(config[:find_column] => r[:find_column])
          db_r.update(r) if table[:allow_overwrite]
        else
          tb_class.new(r).save!
        end
      end
    end

  end

  SUPPORTED_FILE_EXT.each do |fx|
    define_method "to_#{fx}" do |table|
        dir = table[:export_file_location]
        FileUtils.mkdir(dir) unless File.directory?(dir)
        File.open("#{dir}/#{table_name}.#{format}","w") do |f|
          f.write rows.public_send("to_#{format}")
        end
    end
  end
end
