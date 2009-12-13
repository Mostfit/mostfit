if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')
require "roo"

namespace :excel do
  desc "Convert excel sheet into a bunch of csvs"
  task :to_csv, :directory, :filename do |task, args|
    debugger
    excel = Excel.new(File.join(Merb.root, "uploads", args.directory, args.filename))
    excel.sheets.each{|sheet|
      excel.default_sheet=sheet
      excel.to_csv(File.join(Merb.root, "uploads", args.directory, sheet))
    }
  end
end
