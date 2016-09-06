Takenoko.config do |conf|

  #Global Spreadsheet id, optain via url of your spreadsheet
  # conf.sheet_id = "SPREADSHEET_ID"

  # Path to service account cridential file when using account service permission
  # If not set, Takenoko will use peronal cridential auto matically and as you for permission at the first time via command line
  # conf.google_cridential_file = "path to google credential file.json"

  # Path to mapping file, if not be set, Takenoko will fetch all worksheet and export base on worksheet
  # conf.mapping_file = "path to mapping file.yml"


  # GLOBAL CONFIG, you can overwrite under config for each table in mapping_file.yml
  # Export file format, default :csv, support: csv,yaml,json
  # conf.file_extension = :csv

  # Truncate all data before saving, default: false
  # conf.truncate_all_data = false

  # Export file location, default: db/spreadsheet
  # conf.export_file_location = "db/spreadsheet"

  # Allow overwrite duplicated row, default: true
  # conf.allow_overwrite = true

end