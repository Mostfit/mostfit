class Upload
  attr_accessor :log, :directory, :filename

  def initialize(filename, uid=nil)
    @directory = uid||UUID.generate
    @filename  = filename
  end

  def move(tempfile)
    File.makedirs(File.join(Merb.root, "uploads", directory))
    FileUtils.mv(tempfile, File.join(Merb.root, "uploads", directory, filename))
  end

  def self.find(directory)
    Dir.entries(File.join(Merb.root, "uploads", directory)).collect{|file|
      /.xls$/.match(file)
    }.compact
  end

  def process_excel_to_csv
    `rake 'excel:to_csv[#{directory}, #{filename}]'`
  end

  def load_csv(log=nil)
    models = [StaffMember, Branch, Center, ClientGroup, Client, FundingLine, LoanProduct, Loan, Payment]
    funding_lines, loans = {}, {}
    User.all.each{|u|
      u.destroy if not u.login=="admin"
    }
    models.each{|model|      
      model.all.destroy!
      next unless File.exists?(File.join(Merb.root, "uploads", @directory, model.to_s.snake_case.pluralize))
      log.info("Destroying old records for #{model.to_s.plural} (if any)") if log
      log.info("Creating #{model.to_s.plural}") if log
      headers = {}
      FasterCSV.open(File.join(Merb.root, "uploads", @directory, model.to_s.snake_case.pluralize), "r").each_with_index{|row, idx|
        if idx==0
          row.to_enum(:each_with_index).collect{|name, index| 
            headers[name.downcase.gsub(' ', '_').to_sym] = index
          }
        else
          begin
            status, record = 
              if model == Loan
                model.from_csv(row, headers, funding_lines)
              elsif model==Payment
                model.from_csv(row, headers, loans)
              else
                model.from_csv(row, headers)
              end

            if status
              #Storing funding lines and loans for serial number reference
              funding_lines[row[headers[:serial_number]]] = record if model==FundingLine
              loans[row[headers[:serial_number]]]         = record if model==Loan
              log.info("Created #{idx-99} - #{idx+1}. Some more left")    if idx%100==99
            else
              log.error("<font color='red'>#{model}: Problem in inserting #{row[headers[:serial_number]]}. Reason: #{record.errors.to_a.join(', ')}</font>") if log
            end
          rescue Exception => e
            log.error("<font color='red'>#{model}: Problem in inserting #{model} #{row[headers[:serial_number]]}. Insert it manually later</font>") if log
            log.error("<font color='red'>#{model}: #{e.message}</font>") if log
          end
        end    
      }
      log.info("<font color='#8DC73F'><b>Created #{model.count} #{model.to_s.plural}</b></strong>")
    }
  end
end



#   def process_excel_to_csv
#     excel = Excel.new(File.join(Merb.root, "uploads", directory, filename))
#     excel.sheets.each{|sheet|
#       excel.default_sheet=sheet
#       excel.to_csv(File.join(Merb.root, "uploads", directory, sheet))
#     }
#     return excel.sheets
#   end
