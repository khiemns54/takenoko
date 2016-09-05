require "google_drive"

module GoogleDrive
  class Worksheet
    define_method "header" do
      rows.first
    end

    define_method "append_row" do |offset=0|
      row_num = self.num_rows + offset + 1
      return GoogleDrive::Alias::Row.new(row_num, [], rows.first, self)
    end

    define_method "populated_rows" do
      header = nil
      populated = []

      rows.each_with_index do |row,index|
        unless header then
          header = row
          next
        end

        populated.push GoogleDrive::Alias::Row.new(index + 1, row, header, self)
      end

      populated
    end
  end
end

module GoogleDrive
  module Alias
    class Row
      attr_reader :row_num
      
      def initialize(row_num, row, header, ws)
        @row_num = row_num
        @row     = row
        @header  = header
        @ws      = ws
      end

      def method_missing(name,value=nil)
        test = name.to_s.gsub(/=$/,'')

        if @header.include?(test) then
          col_num = @header.find_index(test)
          super unless col_num

          col_num += 1
          if name.match(/=$/) then
            @ws[@row_num,col_num] = value
          else
            return @ws[@row_num,col_num]
          end
        else
          super
        end
      end
    end
  end
end