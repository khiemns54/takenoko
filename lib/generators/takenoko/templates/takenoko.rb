Takenoko.config do |conf|

  # Path to service account cridential file when using account service permission
  # If not set, Takenoko will use persional cridential auto matically and as you for permission at the first time via command line
  # conf.google_cridential_file = "path to google credential file.json"

  # Path to mapping file, if not be set, Takenoko will fetch all worksheet and export base on worksheet
  # conf.mapping_file = "path to mapping file.yml"


  # GLOBAL CONFIG, you can overwrite under config for each table in mapping_file.yml
  # Global Spreadsheet id, optain via url of your spreadsheet
  # conf.sheet_id = "SPREADSHEET_ID" ###IMPORTANT###, Must set this value here or in mapping file

  # Export file format, default :csv, support: csv,yaml,json
  # conf.file_extension = :csv

  # Truncate all data before saving, default: false
  # conf.truncate_all_data = false

  # Export file location, default: db/spreadsheet
  # conf.export_file_location = "db/spreadsheet"

  # Allow overwrite duplicated row, default: true
  # conf.allow_overwrite = true

  # Enable post processing after get row from spreadsheet, default false
  # Define three more method on your post process class to handle it
  # spreadsheet_row_valid? : skip invalid rows, return bool (Optional)
  # postprocess_spreadsheet_row : modify row, return processed row(Optional)
  # postprocess_spreadsheet_table : modify whole talbe, return processed table(Optional)

  # conf.enable_postprocess = false

  # Class for post processing, nil for Class = table class name
  # conf.postprocess_class = nil

end