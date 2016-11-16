namespace :takenoko do
  (Takenoko::SUPPORTED_FILE_EXT.clone << [:db,:file] ).flatten!.each do |output|
    task "all_to_#{output}".to_sym => :environment do
      Takenoko.public_send("all_to_#{output}")
    end

    task "table_to_#{output}".to_sym, [:table] => :environment do |t, args|
      Takenoko.public_send("table_to_#{output}",args[:table])
    end
  end

  task :download_table_files,[:table] => :environment do |t, args|
    Takenoko.download_table_files(args[:table])
  end

  task :download_all_files => :environment do
    Takenoko.download_all_files
  end

  namespace :table do
    (Takenoko::SUPPORTED_FILE_EXT.clone << [:db,:file] ).flatten!.each do |output|
      task "to_#{output}".to_sym, [:table] => "takenoko:table_to_#{output}"
    end

    task "download_attachments",[:table] => "takenoko:download_table_files"
  end

  namespace :all do
    (Takenoko::SUPPORTED_FILE_EXT.clone << [:db,:file] ).flatten!.each do |output|
      task "to_#{output}".to_sym => "takenoko:all_to_#{output}"
    end

    task "download_attachments" => "takenoko:download_all_files"
  end

end