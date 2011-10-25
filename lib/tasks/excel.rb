#if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
#  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
#end
#Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')
require "rubygems"
def to_csv(directory, filename)
  require "roo"
  excel = Excel.new(File.join("uploads", directory, filename))
  excel.sheets.each{|sheet|
    puts sheet
    excel.default_sheet=sheet
      unless File.exists?(File.join("uploads",directory, sheet))
        puts "extracting sheet #{sheet}"
        excel.to_csv(File.join("uploads", directory, sheet))
      else
        puts "skipping #{sheet}"
        return false
      end
  }
  return true
end
puts ARGV
begin
  return to_csv(ARGV[0], ARGV[1])
rescue
  return false
end
