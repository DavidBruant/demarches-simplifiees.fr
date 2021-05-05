namespace :after_party do
  desc 'Deployment task: rename_conservation_extension'
  task rename_conservation_extension: :environment do
    puts "Running deploy task 'rename_conservation_extension'"

    BATCH_SIZE = 20000

    dossiers = Dossier.state_en_construction.where.not(en_construction_conservation_extension: 0.days)
    dossiers.find_each do |dossier|
      dossier.update_column(:conservation_extension, dossier.en_construction_conservation_extension)
    end

    dossiers = Dossier.where(conservation_extension: nil)
    n = (dossiers.count / BATCH_SIZE).ceil + 1
    n.times do
      dossiers.limit(BATCH_SIZE).update_all(conservation_extension: 0.days)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
