require "takenoko"
require "csv"
module Takenoko
  module Exporter
    extend self
    def table_to_db(table)
      tb_class = Object.const_get("::"+table[:class_name])
      import_strategy = table[:import_strategy]
      raise "Class not found:#{table[:class_name]}" unless tb_class <= ActiveRecord::Base
      tb_class.destroy_all if import_strategy == :truncate_all
      table[:rows].each do |r|
        if db_r = tb_class.find_by(table[:find_column] => r[table[:find_column]])
          case import_strategy
            when :overwrite
              db_r.update(r)
            when :fill_empty
              tmp_r = r.clone
              tmp_r.delete_if do |k,v|
                v.blank? || db_r.send(k).present?
              end
              db_r.update(tmp_r)
            when :insert_only
              next
            end
        else
          tb_class.new(r).save!
        end
      end
    end

    def table_to_file(table)
      public_send("table_to_#{table[:file_extension]}",table)
    end

    SUPPORTED_FILE_EXT.each do |fx|
      define_method "table_to_#{fx}" do |table|
          dir = table[:export_file_location]
          FileUtils.mkdir_p(dir) unless File.directory?(dir)
          File.open("#{dir}/#{table[:table_name]}.#{fx}","w") do |f|
            f.write public_send("convert_to_#{fx}",table)
          end
      end
    end

    def convert_to_csv(table)
      CSV.generate do |csv|
        csv << table[:header]
        table[:rows].each do |row|
          csv << table[:header].map {|col| row[col]}
        end
      end
    end

    [:yaml,:json].each do |output|
      define_method "convert_to_#{output}" do |table|
        table[:rows].map{|r| r.to_hash}.public_send("to_#{output}")
      end
    end

    alias convert_to_yml convert_to_yaml
  end

end
