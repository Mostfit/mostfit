# This file is required because we cannot require "roo" in the Merb application due to some conflicting names (Log4R::Logger conflicts with ruby Logger).

require "rubygems"
require "roo"

def to_csv(directory, filename)
  excel = Excel.new(File.join("uploads", directory, filename))
  excel.sheets.each{|sheet|
    puts sheet
    excel.default_sheet=sheet
    unless File.exists?(File.join("uploads",directory, "#{sheet}.csv"))
      puts "extracting sheet #{sheet}"
      excel.to_csv(File.join("uploads", directory, "#{sheet}.csv"))
    else
      puts "skipping #{sheet}"
      return false
    end
  }
  return true
end

begin
  return to_csv(ARGV[0], ARGV[1])
rescue Exception => e
  return e.message
end
