# This file is required because we cannot require "roo" in the Merb application due to some conflicting names (Log4R::Logger conflicts with ruby Logger).

require "rubygems"
require "roo"

def to_csv(directory, filename)
  log_file = File.open(File.join("public","logs", directory), "a")
  excel = Excel.new(File.join("uploads", directory, filename))
  excel.sheets.each{|sheet|
    excel.default_sheet=sheet
    unless File.exists?(File.join("uploads",directory, "#{sheet}.csv"))
      log_file.write "extracting sheet #{sheet}\n"
      excel.to_csv(File.join("uploads", directory, "#{sheet}.csv"))
    else
      log_file.write "skipping #{sheet}\n"
      return false
    end
  }
  log_file.close
  return true
end

begin
  return to_csv(ARGV[0], ARGV[1])
rescue Exception => e
  return e.message
end
