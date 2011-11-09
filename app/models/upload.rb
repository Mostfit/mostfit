class Upload  
  include DataMapper::Resource
  attr_accessor :log, :state_detail_hash

  property :id,           Serial
  property :filename,     String
  property :directory,    String
  property :md5sum,       String, :unique => true
  property :state,        Enum[:new, :uploaded, :extracted, :processing, :complete, :stopped]
  property :state_detail, Text # state_detail is a hash like {:clients => {:last_id => 234, :more_info => "more info"}...}

  property :created_at,   DateTime
  property :updated_at,   DateTime

  belongs_to :user

  has n, :checkers

  MODELS = [:staff_members, :repayment_styles, :loan_products, :funding_lines, :branches, :centers, :client_groups, :clients, :loans]

  if Mfi.first.system_state == :migration
    MODELS.each do |model|
      has n, model
    end
  end

  before :valid? do 
    self.directory ||= UUID.generate
    self.state ||= :new
    self.state_detail = Marshal.dump(@state_detail_hash)
  end

  def self.make(params)
    # our intializer parses the params and moves the tempfile to a sane location
    require 'digest/md5'
    md5sum = Digest::MD5.hexdigest(params[:file][:tempfile].read)
    u = Upload.first_or_new(:filename => params[:file][:filename], :user => params[:user], :md5sum => md5sum)
    u.save if u.new?
    u.move(params[:file][:tempfile].path)
  end

  def excel_file
    # shortcut
    File.join(Merb.root, "uploads", directory, filename)
  end

  def csv_file_for(model)
    f = File.join(Merb.root, "uploads", directory, "#{model.to_s.snake_case}.csv")
    File.exists?(f) ? f : false 
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

  # returns a handle to the Log4R log file and sets the log level
  #
  # @param [Symbol] either :info or :verbose
  def log_file(log_level = :verbose)
    return @log if @log
    require "log4r"
    log_file_name = "#{self.directory}"
    @log       = Log4r::Logger.new log_file_name
    pf        = Log4r::PatternFormatter.new(:pattern => "<b>[%l]</b> %m")
    file_log  = Log4r::FileOutputter.new(log_file_name, :filename => [Merb.root, "public", "logs", self.directory].join("/"), :truncate => false, :formatter => pf)
    @log.add(file_log)
    log_levels = {:info => Log4r::INFO, :verbose => Log4r::DEBUG}
    @log.level = Log4r::DEBUG # log_levels[log_level]
    @log.info("--------------------------------starting #{Time.now}-----------------")
  end

  # picks up where we left off last time
  #
  # @param [Hash] like {:verbose => <boolean>, :erase => <boolean>}
  def cont(options = {:verbose => false, :erase => false})
    log_file(options[:verbose]) unless @log
    if state == :uploaded
      process_excel_to_csv
      cont
    elsif state == :extracted
      load_csv(options)
    end
  end

  # destroys all the entries in the database created by this upload
  def destroy_models
    MODEL.each do |model|
      @log.debug("Erasing #{model_name}")
      self.send(model).aggregate(:id).destroy!
      @log.debug("done")
    end
  end

  # removes the csv files and optionally rolls back the database
  def reset(options = {:verbose => false, :erase => false})
    log_file unless @log
    @log.info("Stopping processing")
    self.state = :uploaded
    self.save
    if false # TODO set this to option[:erase] once done
      @log.info("Erasing records from database")
      destroy_models
    end
    @log.info("deleting csv files")
    FileUtils.rm Dir.glob(File.join("uploads",directory,"*csv"))
  end
  
  # turns an excel file into its constituent worksheets as CSV files
  def process_excel_to_csv
    # DIRTY HACK!
    # there is some gem that conflicts with the name Logger which causes roo to crash upon load.
    # therefore, we run the roo task from a separate ruby file with no gems loaded
    s =  `ruby lib/tasks/excel.rb #{directory} #{filename}`
    @log.info s
    if s
      self.state = :extracted
      self.save
    end
  end
  
  # returns an array containing names of the csv files in the directory
  def csv_files
    Dir.glob(File.join("uploads", directory, "*csv")).map{|c| c.split("/")[-1]}
  end

  # Loads the extracted CSV files into the database. Params are passed in the options hash as follows
  #
  # @param [Hash] the options to use. Valid options are {:erase => <boolean>, :verbose => <boolean>}
  #   :erase will erase old data, :verbose prints debugging information
  def load_csv(options)
    erase = options[:erase]; verbose = options[:verbose]
    funding_lines, loans = {}, {}
    if csv_files.blank?
      @log.error("No CSV files found here. Exiting")
      return
    end
    
    MODELS.each {|model|
      error_count = 0
      error_file = File.open(File.join("uploads",directory,"#{model.to_s}_errors.csv"),"w")
      next unless file_name = csv_file_for(model)                                                             # no CSV file? next!
      model = Kernel.const_get(model.to_s.singularize.camel_case)
      @log.info("Creating #{model.to_s.plural}")

      # first find out which fields are required to be unique
      # we read them first so as not to waste time on entries already in the database
      _o =  (model.send(:properties).map{|x| x.name if x.unique?}.compact - [:id])                                  # all unique properties
      _o += model.validators.first[1].map{|x| x.field_name if x.is_a? DataMapper::Validate::UniquenessValidator}.compact    # all Uniqueness validator fieldnames
      unique_field = _o[0]
      @log.debug(unique_field ? unique_field.to_s : "No unique field")
      unless unique_field
        @log.error("Atleast one property in #{model} must be unique") 
        break
      end

      # get the uniques
      uniques = model.all.aggregate(unique_field)
      headers = {}; done = 0; skipped = 0;
      FasterCSV.open(file_name, "r").each_with_index{|row, idx|
        error = true
        if idx==0
          row.to_enum(:each_with_index).collect{|name, index| 
            headers[name.downcase.gsub(' ', '_').to_sym] = index
          }
          headers[:upload_id] = headers.keys.count
            
          error_file.write(row.to_csv)
        else
          row.push(self.id)
          if uniques.include?(row[headers[unique_field]])
            @log.debug("Skipping unique #{model} with #{unique_field} #{row[headers[unique_field]]}")
            skipped += 1
            next
          end
          begin
            debugger if model == Loan
            status, record = model.from_csv(row, headers)
            if status
              error = false
              @log.debug("Created #{model} #{record.id}")
              done += 1
              @log.info("Created #{idx-99} - #{idx+1}. Some more left")    if idx%100==99
            else
              @log.error("<font color='red'>#{model}: Problem in inserting #{row[headers[:serial_number]]}. Reason: #{record.errors.to_a.join(', ')}</font>") if log
            end
          rescue Exception => e
            @log.error("<font color='red'>#{model}: Problem in inserting #{model} #{row[headers[:serial_number]]}. Insert it manually later</font>") if log
            @log.error("<font color='red'>#{model}: #{e.message}</font>") if log
          ensure
            if error
              error_file.write(row.to_csv)         # log all errors in a separate csv file
              error_count += 1                    # so we can iterate down to perfection
            end
          end
        end    
      }
      @log.info("<font color='#8DC73F'><b>Created #{done} #{model.to_s.plural}</b></strong> Skipped #{skipped}") 
      error_file.close
    }
  end
end

