#Takenoko
##Description
Rails gem for getting data from Google spreedsheet then export to files or database via simple interface and rake tasks
##
##What's new in versions 0.2.0
* Simpler,smarter, config, easier to use by using spreadsheet as config
* Download row attached files
* Mapping file will be use only to overwrite global config
* Fix minor bugs

##Install
### 1._Gemfile_

    gem "takenoko"

### 2._Generate initializer_

    #Generate config/initializers/takenoko.rb
    rails generate takenoko:config

_Update config/initializers/takenoko.rb_

    conf.sheet_id = "SPREADSHEET_ID"    


Other global options, you can overwrite these options in mapping file for each table

|Option|Require|Default|Description|Value|Overwrite(*)|
|---|---|---|---|---|---|
|google_cridential_file|Optional||Only use when using service account authorizaion. If not set, Takenoko will use persional cridential auto matically and as you for permission at the first time via command line|String|No|
|personal_cridential_file|Optional|config/my_cridential.json|Location for saving your personal cridential|String|No|
|sheet_id|Optional||Spreadsheet id, optain via url of your spreadsheet,**IMPORTANT**, Must set this value here or in mapping file|String|Yes|
|mapping_file|Optional||Use when you want customize exporting, overwrite default setting for each tables, if not set takenoko will export all worksheet except skipped one.|String|No|
|file_extension|_Optional_|csv| Export file format|csv,yaml,json|Yes|
|export_file_location|_Optional_|db/spreadsheet|Location for exported files|String|Yes|
|truncate_all_data|_Optional_|false|Truncate table before saving data|bool|Yes|
|allow_overwrite|_Optional_|true|Overwrite duplicated row|bool|Yes|
|enable_postprocess|Optional|false|Enable validator and filter|bool|Yes|
|postprocess_class|Optional|nil|Class for post processing, nil for Class = table class name|String|Yes|
|always_reload|Optional|true|Always reload spreadsheet-database mapping data|bool|No|
|download_location|Optional|tmp/attach_files|Downloaded files location|String|Yes|
|folder_id|Optional|nil|Google drive folder id, where your attached files is being stored|String|Yes|

You can refer **[HERE](https://github.com/gimite/google-drive-ruby/blob/master/doc/authorization.md)** for how to get cridential_file when using service account permission

**"*"**: Allow overwrite in mapping_file.yaml

###3. Create mapping_file.yaml
    
    tables:
      table1:
        worksheet_id: #
        folder_id:...
        columns_mapping:
          table_col_1:spread_sheet_colA
          table_col_2:spread_sheet_colB
          table_col_3:spread_sheet_colC
        attach_files
        - column_name: column
      table2:
        spreadsheet_id: Example

      table3: (nil or false to skip)
    ...

Tables: Hash of tables

Table option

|Option|Require|Default|Description|Value|
|---|---|---|---|---|
|worksheet_id|Optional||Worksheet gid|Integer|
|worksheet|Optional|Work sheet name|Use to find worksheet when worksheet_id is not set|String|
|columns_mapping|Optional||Use when worksheet column difference from database column, if spreadsheet be set to false, the column will be skipped |Hash|
|table_name|Optional|key name|Table name|String|
|class_name|Optional|singular camel form of _table_name_| Model class name| String|
|find_column|_Optional_|id|By default takenoko use worksheet row number as id of row, you have to set this option for find and replace duplicated rows|String|
|sheet_id<br/>file_extension<br/>export_file_location<br/>truncate_all_data<br/>allow_overwrite<br/>enable_postprocess<br/>postprocess_class</br>download_location</br>folder_id</br>|Optional||Overwrite global config||


##Usage
### Google spreadsheet format
First row will be header definition(Use # to skip rows)

|name|code|price|description|...|
|---|---|---|---|---|
|Beer|1|1000|Super beer|...|
|Drug|2|9999|Super drug|...|
|...|...|...|...|...|

### Takenoko usage
For all tables

    Takenoko.all_to_db
    Takenoko.all_to_file
    Takenoko.all_to_yaml
    ...    

For single table

    Takenoko.table_to_db(table_name)
    Takenoko.table_to_file(table_name)
    Takenoko.table_to_yaml(table_name)


### Rake task
For all tables

    rake takenoko:all_to_db
    rake takenoko:all_to_file
    rake takenoko:all_to_yaml
    ...    

For single table

    rake takenoko:table_to_db[table_name]
    rake takenoko:table_to_file[table_name]
    rake takenoko:table_to_yaml[table_name]


### Validation and filtering

Takenoko uses three method for post processing. Defined them in your postprocess_class. By default, postprocess_class will be class_name in mapping_file.yml

+ spreadsheet_row_valid?(row) => __bool__ : skip invalid rows (Optional)
+ postprocess_spreadsheet_row(row) => __row__ : modify row, return processed row(Optional)
+ postprocess_spreadsheet_table(table) => __row__ : modify whole dowloaded table, return processed table(Optional)

### Download attach files

Sometimes, you set row to path of files in google drive, takenoko allows you to download these files and save in local folder. We are preparing for takenoko-s3 extensions to auto download file from googledrive then upload to AWS s3

Specify rows that have attached files in mapping_file.yml
    
    tables:
      table1:
        ....
        attach_files
        - column_name: image
          folder_id: another_folder_id
          download_location: image #download_location/table_name/image/file_name
        - column_name: thumb
        ....

  Usage

    Takenoko.download_table_files(table_name)
    Takenoko.download_all_files

  Rake tasks

    rake takenoko:download_table_files[:table_name]
    rake takenoko:download_all_files

### Skipping worksheet and column

Just put '#' before your worksheet name or column name to skip it, or set table value to nil/false in mapping file
