module Takenoko
  class GoogleClient
    def initialize(cridential_file)
      @session ||= GoogleDrive.saved_session(cridential_file)
    end

    def get_table(table_name)
      table = Takenoko.table_config(table_name)
      raise "GoogleDrive: Sheet not found" unless sheet = @session.spreadsheet_by_key(table['sheet_id'])
      raise "GoogleDrive: Worksheet not found: worksheet_id #{table['worksheet_id']}" unless worksheet = sheet.worksheet_by_gid(table['worksheet_id'])
      header = worksheet.header.select {|h| table[:columns_mapping].keys.include?(h)}
      rows = worksheet.populated_rows.map do |r|
        hash = HashWithIndifferentAccess.new
        table['columns_mapping'].each do |key,val|
          begin
            hash[key] = r.public_send(val)
          rescue Exception => e
            if key == 'id'
              hash[key] = r.row_num - 1
            else
              hash[key] = nil
            end
          end
        end
        hash
      end
      table[:rows] = rows
      return table
    end
  end
end