class Upload
  def directory
    @directory
  end

  def filename
    @filename
  end

  def initialize(filename)
    @directory = UUID.generate
    @filename  = filename
    @log       = Logger.new(File.join(Merb.root, "public", "logs", @directory))
    @log.level = Logger::WARN
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
    excel = Excel.new(File.join(Merb.root, "uploads", directory, filename))
    excel.sheets.each{|sheet|
      excel.default_sheet=sheet
      excel.to_csv(File.join(Merb.root, "uploads", directory, sheet))
    }
    return sheets
  end

  def load_csv
    models = [StaffMembers, Branch, Center, Client, FundingLine, LoanProduct, Loan, Payment]
    models.each{|model|
      headers = {}
      CSV.parse(File.join(file.directory, model.to_s.snake_case.pluralize)).each_with_index{|row, idx|
        begin
          if idx==0
            row.to_enum(:each_with_index).collect{|name, index| 
              headers[name.to_sym] = index
            }
          rescue
            @log.fatal("#{model}: Problem in getting headers for #{model}. You will need to upload the excel sheet all over again")
          end
        else
          begin
            if record = model.from_csv(row, headers)
              @log.info("#{model}: Inserted row #{row[headers[:serial_number]]}")
            else
              @log.warn("#{model}: Problem in inserting #{row[headers[:serial_number]]}. Reason: #{record.errors}")
            end
          rescue
            @log.warn("#{model}: Problem in inserting #{model} #{row[headers[:serial_number]]}. Insert it manually later")
          end
        end    
      }
    }
  end
end
