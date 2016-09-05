module Takenoko
  class GoogleClient
    def initialize(cridential_file)
      @cridential = JSON.parse(File.read(cridential_file)).with_indifferent_access
    end

    def get_table(table_name)
      table = Takenoko.table_config(table_name)
      raise "GoogleDrive: Sheet not found" unless sheet = session.spreadsheet_by_key(table['sheet_id'])
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

    def session
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
  end
end