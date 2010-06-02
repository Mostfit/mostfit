if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')
require "log4r"

namespace :mostfit do
  desc "Create DB from excel sheet"
  task :upload, :directory, :filename do |task, args|
    #    include Log4r
    filename  = args[:filename]
    directory = args[:directory]

    file      = Upload.new(filename, directory)          
    #create logger
    log       = Log4r::Logger.new 'upload_log'
    pf        = Log4r::PatternFormatter.new(:pattern => "<b>[%l]</b> %m")
    file_log  = Log4r::FileOutputter.new('output_log', :filename => [Merb.root, "public", "logs", file.directory].join("/"), :truncate => false, :formatter => pf)
    log.add(file_log) 
    log.level = Log4r::INFO

    log.info("File has been uploaded to the server. Now processing it into a bunch of csv files")
    puts `ruby #{Merb.root}/lib/tasks/excel.rb #{directory} #{filename}`
    log.info("CSV extraction complete. Processing files.")
    file.load_csv(log)
    log.info("CSV files are now loaded into the DB. Creating loan schedules. This may take a few minutes.")
    `rake mostfit:mock:update_all_history`
    log.info("<h2>Processing complete! Your MIS is now ready for use. Please take a note of all the errors reported here(if any) and rectify them.</h2>")            
  end
end
