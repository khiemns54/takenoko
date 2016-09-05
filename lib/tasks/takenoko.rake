namespace :takenoko do
  (Takenoko::SUPPORTED_FILE_EXT.clone << :db ).each do |output|
    task "all_to_#{output}".to_sym => :environment do
      Takenoko.public_send("all_to_#{output}")
    end

    task "table_to_#{output}".to_sym, [:table] => :environment do |t, args|
      Takenoko.public_send("table_to_#{output}",args[:table])
    end
  end
end