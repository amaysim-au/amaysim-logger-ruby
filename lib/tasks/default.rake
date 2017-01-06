task :default do
  Rake::Task['spec'].invoke
  Rake::Task['rubocop'].invoke
end
