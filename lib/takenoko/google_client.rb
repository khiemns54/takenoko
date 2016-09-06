module Takenoko
  class GoogleClient
    def initialize(cridential_file=nil)
      if cridential_file && ::File.exist?(cridential_file)
        @cridential = JSON.parse(File.read(cridential_file)).with_indifferent_access
      end
    end

    def get_table(table_name)
      table = Takenoko.table_config(table_name)
      raise "GoogleDrive: Sheet not found" unless sheet = session.spreadsheet_by_key(table['sheet_id'])

      if table[:worksheet_id].present?
        worksheet = sheet.worksheet_by_gid(table[:worksheet_id])
        table[:worksheet] = worksheet.title
      elsif table[:worksheet].present?
        raise "Worksheet #{table[:worksheet]} not found" unless worksheet = sheet.worksheet_by_title(table[:worksheet])
        table[:worksheet_id] = worksheet.gid.to_i
      elsif
        raise "You must specify worksheet or worksheet_id if mapping_file.yml"
      end

      update_table_config(table,worksheet.header)

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

    def session
      unless @cridential
        return GoogleDrive.saved_session(Takenoko.personal_cridential_file)
      end

      key = OpenSSL::PKey::RSA.new(@cridential['private_key'])
      auth = Signet::OAuth2::Client.new(
        token_credential_uri: @cridential['token_uri'],
        audience: @cridential['token_uri'],
        scope: %w(
          https://www.googleapis.com/auth/drive
          https://spreadsheets.google.com/feeds/
        ),
        issuer: @cridential['client_email'],
        signing_key: key
      )

      auth.fetch_access_token!
      session = GoogleDrive.login_with_oauth(auth.access_token)
      return session
    end

    def spreadsheet(sheet_id=Takenoko.sheet_id)
      session.spreadsheet_by_key(sheet_id)
    end

    private
    def update_table_config(table,ws_header)
      ws_header = ws_header.select do |col|
        col.present? && ! col.match(/\s*#.*/)
      end

      if(table[:columns_mapping].blank?)
        columns_mapping = {}
        ws_header.each do |col| columns_mapping[col.to_sym] = col end
        table[:columns_mapping] = columns_mapping
      end

      unless table[:columns_mapping].key?(table[:find_column])
          table[:columns_mapping][table[:find_column]] = nil 
      end

      table[:columns_mapping].each do |s_col,db_col|
        table[:columns_mapping][s_col] = s_col unless db_col 
      end

      table[:header] = table[:columns_mapping].keys
      return table
    end
  end
end