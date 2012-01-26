class Mfi
  include DataMapper::Resource
  MinDateFrom = {:in_operation_since => "In operation since date", :today => "Today's date"}

  SYSTEM_STATES = [:running, :stopped, :migration, :admin_only]

  def self.default_repository_name
    :abstract 
  end 

  attr_accessor :subdomain, :city_name, :state_id, :district_id, :logo, :fetched

  property :id,           Serial, :nullable => false, :index => true
  property :name,         String, :nullable => true, :index => true
  property :address,      Text
  property :website,      String
  property :telephone,    String

  property :in_operation_since, Date, :nullable => false, :index => true, :default => Date.new(2000, 1, 1)

  property :number_of_past_days, Integer, :nullable => true, :index => true, :default => 5
  property :min_date_from, Enum.send('[]', *MinDateFrom.keys), :nullable => true, :index => true, :default => :in_operation_since

  property :number_of_future_transaction_days, Integer, :nullable => true, :index => true, :default => 0

  property :number_of_future_days, Integer, :nullable => true, :index => true, :default => 100

  property :date_box_editable, Boolean, :default => true, :index => true
  property :allow_grt_date_on_form, Boolean, :default => false, :index => true

  property :email, String, :nullable => false, :index => true, :format => :email_address
  property :created, Boolean, :nullable => false, :index => true, :default => false
  property :color, String, :nullable => true
  property :logo_name,  String, :nullable => true
  property :accounting_enabled, Boolean, :default => false, :index => true
  property :transaction_logging_enabled, Boolean, :default => false, :index => true
  property :event_model_logging_enabled, Boolean, :default => false, :index => true
  property :dirty_queue_enabled, Boolean, :default => false, :index => true
  property :map_enabled, Boolean, :default => false, :index => true
  property :branch_diary_enabled, Boolean, :default => false, :index => true
  property :stock_register_enabled, Boolean, :default => false, :index => true
  property :asset_register_enabled, Boolean, :default => false, :index => true

  property :allow_choice_of_repayment_style, Boolean, :default => true, :index => true
  property :default_repayment_style, Enum.send('[]', *REPAYMENT_STYLES), :default => NORMAL_REPAYMENT_STYLE, :index => true
  property :generate_day_sheet_before, Integer, :default => 1, :max => 5

  property :currency_format,  String,  :nullable => true, :length => 20, :default => "in_with_paise"
  property :session_expiry,   Integer, :nullable => true, :min => 60, :max => 86400
  property :password_change_in, Integer, :nullable => true
  property :org_locale, String
  property :prefered_date_pattern, String, :nullable => true
  property :prefered_date_separator, String, :nullable => true
  property :prefered_date_style, String, :nullable => true

  property :report_access_rules, Yaml, :nullable => true, :default => {}

  property :system_state, Enum.send('[]', *SYSTEM_STATES), :default => :running

  property :main_text, Text, :nullable => true, :lazy => true
  validates_length :name, :min => 0, :max => 20
  before :valid?, :save_image
  
  validates_with_method :check_contact_details, :if => Proc.new{|m| m.new?}

  def self.first
    if $globals and $globals[:mfi_details] and $globals[:mfi_details].fetched==Date.today
      $globals[:mfi_details]
    else
      mfi = if File.exists?(File.join(Merb.root, "config", "mfi.yml"))
              Mfi.new(YAML.load(File.read(File.join(Merb.root, "config", "mfi.yml"))).only(*Mfi.properties.map(&:name)))
            else
              Mfi.new(:name => "Mostfit", :fetched => Date.today)  
            end
      mfi.fetched = Date.today
      $globals ||= {}
      $globals[:mfi_details] = mfi
      return mfi
    end
  end
  
  def self.activate
    mfi = Mfi.first
    mfi.set_variables
  end
  
  def save
    $globals ||= {}
    $globals[:mfi_details] = Mfi.new(self.attributes)
    self.in_operation_since = self.in_operation_since.strftime("%Y-%m-%d")
    File.open(File.join(Merb.root, "config", "mfi.yml"), "w"){|f|
      f.puts self.to_yaml
    }
    FileUtils.touch(File.join(Merb.root, "tmp", "restart.txt"))    
    Mfi.activate
  end

  def save_image
    if self.logo and self.logo[:filename] and not self.logo[:filename].blank? and ["image/jpeg", "image/png", "image/gif"].include?(self.logo[:content_type])      
      File.makedirs(File.join(Merb.root, "public", "images", "logos"))
      FileUtils.mv(self.logo[:tempfile].path, File.join(Merb.root, "public", "images", "logos", self.logo[:filename]))
      File.chmod(0755, File.join(Merb.root, "public", "images", "logos", self.logo[:filename]))
      self.logo_name = self.logo[:filename]
    end
  end

  def set_currency_format
    if format = currency_format and not format.blank? and Numeric::Transformer.instance_variable_get("@formats").keys.include?(format.to_sym)
      Numeric::Transformer.change_default_format(format.to_sym)
    else
      Numeric::Transformer.change_default_format(:mostfit_default)
    end
  end
  
  def set_variables
    self.report_access_rules = REPORT_ACCESS_HASH if not self.report_access_rules or self.report_access_rules == {}
    Misfit::Config::DateFormat.compile
    set_currency_format
    DirtyLoan.start_thread
  end

  def date_format
    mfi = Mfi.first
    style = mfi.prefered_date_style || DEFAULT_DATE_STYLE
    case style
    when "MEDIUM"
      return MEDIUM_DATE_PATTERN
    when "LONG"
      return LONG_DATE_PATTERN
    when "FULL"
      return FULL_DATE_PATTERN
    else
      pattern =  (mfi.prefered_date_pattern if not mfi.prefered_date_pattern.blank?) || DEFAULT_DATE_PATTERN
      separator = (mfi.prefered_date_separator if not mfi.prefered_date_separator.blank?) || DEFAULT_DATE_SEPARATOR
      pattern = pattern.to_s.gsub(FORMAT_REG_EXP, separator.to_s)
      return pattern
    end
  end

  # How about some normal validations?
  def check_contact_details
    return true if address and telephone
    return [false, "Please enter your address and telephone number"]
  end


end
