#if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
#  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
#end
#Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace :excel do
  desc "Convert excel sheet into a bunch of csvs"
  task :to_csv, :directory, :filename do |task, args|
    require "roo"
    excel = Excel.new(File.join("uploads", args.directory, args.filename))
    excel.sheets.each{|sheet|
      puts sheet
      excel.default_sheet=sheet
      if File.exists?(File.join("uploads",args.directory, sheet))
        puts "extracting sheet #{sheet}"
        excel.to_csv(File.join("uploads", args.directory, sheet))
      else
        puts "skipping #{sheet}"
      end
    }
  end
end
