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
    debugger
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

  def continue
    # picks up where we left off last time
    while self.state != :complete
      debugger
      if state == :uploaded
        process_excel_to_csv
      elsif state == :extracted
        load_csv
      end
    end
  end

  def process_excel_to_csv
    `ruby lib/tasks/excel.rb #{directory} #{filename}`
    debugger
    self.state = :extracted
    self.save
  end

  def load_csv(log=nil, erase=false)
    debugger
    models = [StaffMember, Branch, RepaymentStyle, FundingLine, LoanProduct, Center, ClientGroup, Client,  Loan, Payment]
    funding_lines, loans = {}, {}
    User.all.each{|u|
      u.destroy if not u.login=="admin"
    }
    models.each{|model| 
      if erase     
        model.all.destroy!
        log.info("Destroying old records for #{model.to_s.plural} (if any)") if log
      end
      next unless File.exists?(File.join(Merb.root, "uploads", directory, model.to_s.snake_case.pluralize))
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
