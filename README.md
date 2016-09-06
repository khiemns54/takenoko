#Takenoko
##Description
Rails gem for getting data from Google spreedsheet then export to files or database via simple interface and rake tasks
##Install
### 1._Gemfile_

    gem "takenoko", "~> 0.0.3"

### 2._Generate initializer_

    #Generate config/initializers/takenoko.rb
    rails generate takenoko:config

_Update config/initializers/takenoko.rb_

    #require
    google_cridential_file : path_to_google_cridential_file.json

You can refer **[HERE](https://github.com/gimite/google-drive-ruby/blob/master/doc/authorization.md)** for how to get cridential_file

    #require
    mapping_file : path_to_mapping_file.yml

Other global options, you can overwrite these options in mapping file for each table

|Option|Require|Default|Description|Value|
|---|---|---|---|---|
|file_extension|_Optional_|csv| Export file format|csv,yaml,json|
|export_file_location|_Optional_|db/spreadsheet|Location for exported files|String|
|truncate_all_data|_Optional_|false|Truncate table before saving data|bool|
|allow_overwrite|_Optional_|true| table before saving data|bool|

###3. Create mapping_file.yaml
    
    default: &default
      sheet_id: #Spreadsheet ID
    tables:
      table1:
        <<: *default
        worksheet_id: #
        columns_mapping:
          table_col_1:spread_sheet_colA
          table_col_2:spread_sheet_colB
          table_col_3:spread_sheet_colC

      table2:
        <<: *default
    ...

Tables: Hash of tables

Table option

|Option|Require|Default|Description|Value|
|---|---|---|---|---|
|**sheet_id**|**Required**||Google spreadsheet id|String|
|**worksheet_id**|**Required**||Worksheet gid|Integer|
|**columns_mapping**|**Required**||Mapping database column(key) to spreadsheet column(value), if spreadsheet column not be set, it will be set to database column automatically, **Caution:** only these columns will be export so list all columns that you need to import here|Hash|
|**table_name**|Optional|key name|Table name|String|
|**class_name**|Optional|singular camel form of _table_name_| Model class name| String|
|**find_column**|_Optional_|id|By default takenoko use worksheet row number as id of row, you have to set this option for find and replace duplicated rows|String|
|file_extension|_Optional_|csv| Export file format|csv,yaml,json|
|export_file_location|_Optional_|db/spreadsheet|Location for exported files|String|
|truncate_all_data|_Optional_|false|Truncate table before saving data|bool|
|allow_overwrite|_Optional_|true| table before saving data|bool|

##Usage
### Google spreadsheet format
First row will be header definition

|name|code|price|description|...|
|---|---|---|---|---|
|Beer|1|1000|Super beer|...|
|Drug|2|9999|Super drug|...|
|...|...|...|...|...|

### Takenoko usage
For all tables

    Takenoko.all_to_db
    Takenoko.all_to_yaml
    ...    

For single table

    Takenoko.table_to_db(table_name)
    Takenoko.table_to_yaml(table_name)


### Rake task
For all tables

    rake takenoko:all_to_db
    rake takenoko:all_to_yaml
    ...    

For single table

    rake takenoko:table_to_db[table_name]
    rake takenoko:table_to_yaml[table_name]

