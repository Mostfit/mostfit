class Upload
  include DataMapper::Resource
  attr_accessor :log, :state_detail_hash

  property :id,           Serial
  property :filename,     String
  property :directory,    String
  property :md5sum,       String, :unique => true
  property :state,        Enum[:new, :uploaded, :extracted, :processing, :complete]
  property :state_detail, Text # state_detail is a hash like {:clients => {:last_id => 234, :more_info => "more info"}...}

  property :created_at,   DateTime
  property :updated_at,   DateTime

  belongs_to :user

  before :valid? do 
    self.directory ||= UUID.generate
    self.state ||= :new
    self.state_detail = Marshal.dump(@state_detail_hash)
  end

  before :create do
  end

  def self.make(params)
    # our intializer parses the params and moves the tempfile to a sane location
    require 'digest/md5'
    md5sum = Digest::MD5.hexdigest(params[:file][:tempfile].read)
    u = Upload.first_or_new(:filename => params[:file][:filename], :user => params[:user], :md5sum => md5sum)
    u.save if u.new?
    u.move(params[:file][:tempfile].path)
  end

  def get_state
    # checks if the file actually exists
    File.exists?(my_file) ? state : "deleted"
  end

  def read
    File.read(my_file)
  end

  def my_file
    # shortcut
    File.join(Merb.root, "uploads", directory, filename)
  end

  def details
    # use this method to check the details as it serializes the state_details object
    @state_detail_hash ||= Marshal.load(self.state_detail)
  end
  
  def move(tempfile)
    # moves the tempfile to a nice location
    File.makedirs(File.join(Merb.root, "uploads", directory))
    FileUtils.mv(tempfile, File.join(Merb.root, "uploads", directory, filename))
    self.state = :uploaded
    self.save
  end

  def self.find(directory)
    Dir.entries(File.join(Merb.root, "uploads", directory)).collect{|file|
      /.xls$/.match(file)
    }.compact
  end

  def cont
    # picks up where we left off last time
    require "log4r"
    log_file_name = "#{self.directory}"
    log       = Log4r::Logger.new log_file_name
    pf        = Log4r::PatternFormatter.new(:pattern => "<b>[%l]</b> %m")
    file_log  = Log4r::FileOutputter.new(log_file_name, :filename => [Merb.root, "public", "logs", self.directory].join("/"), :truncate => false, :formatter => pf)
    log.add(file_log) 
    p file_log
    log.level = Log4r::INFO

    if state == :uploaded
      process_excel_to_csv
      cont
    elsif state == :extracted
      load_csv(log)
    end
  end
  
  def process_excel_to_csv
    `ruby lib/tasks/excel.rb #{directory} #{filename}`
    self.state = :extracted
    self.save
  end
  
  def load_csv(log=Nothing, erase=false)
    models = [StaffMember, RepaymentStyle,  LoanProduct, FundingLine, Branch, Center, ClientGroup, Client,  Loan, Payment]
    funding_lines, loans = {}, {}
    if erase
      log.info("Destroying old data as requested")
      models.each{|model| 
        model.all.destroy!
        log.info("Destroying old records for #{model.to_s.plural} (if any)")
      }
    end
    models.each {|model|
      unless File.exists?(File.join(Merb.root, "uploads", directory, model.to_s.snake_case.pluralize))
        log.info("not found #{model} csv file")
        next
      end
      log.info("Creating #{model.to_s.plural}")

      # first find out which fields are required to be unique
      # we read them first so as not to waste time on entries already in the database
      _o =  (model.send(:properties).map{|x| x.name if x.unique?}.compact - [:id])                                  # all unique properties
      _o += model.validators.first[1].map{|x| x.field_name if x.is_a? DataMapper::Validate::UniquenessValidator}.compact    # all Uniqueness validator fieldnames
      unique_field = _o[0]
      log.info(unique_field ? unique_field.to_s : "No unique field")
      log.error("Atleast one property in #{model} must be unique") unless unique_field
      break
      # get the uniques
      uniques = model.all.aggregate(unique_field)
      
      headers = {}
      FasterCSV.open(File.join(Merb.root, "uploads", @directory, model.to_s.snake_case.pluralize), "r").each_with_index{|row, idx|
        if idx==0
          row.to_enum(:each_with_index).collect{|name, index| 
            headers[name.downcase.gsub(' ', '_').to_sym] = index
          }
        else
          if uniques.include?(row[headers[unique_field]])
            log.info("Skipping unique #{row[headers[unique_field]]}")
            next
          end
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
              if model==Loan
                loans[row[headers[:serial_number]]]         = record 
                record.update_history
              end
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
      log.info("<font color='#8DC73F'><b>Created #{model.count} #{model.to_s.plural}</b></strong>") if log
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
