class Mfi
  include DataMapper::Resource
  DateFormats = ["%d-%m-%Y", "%Y-%m-%d", "%Y-%d-%m", "%d/%m/%Y", "%m/%d/%Y", "%d-%m-%y", "%y-%m-%d", "%y-%d-%m", "%d/%m/%y", "%m/%d/%y", "%d %B, %Y", "%d %B, %Y", "%A, %d %B %Y", "%A, %d %m %Y"]
  MinDateFrom = {:in_operation_since => "In operation since date", :today => "Today's date"}

  def self.default_repository_name
    :abstract 
  end 

  attr_accessor :subdomain, :city_name, :state_id, :district_id, :logo, :fetched

  property :id, Serial, :nullable => false, :index => true
  property :name, String, :nullable => false, :index => true
  property :address, Text, :nullable => false, :index => false
  property :website, String
  property :telephone, String, :nullable => false, :index => true
  property :number_of_clients, Integer, :nullable => false, :index => true
  property :number_of_branches, Integer, :nullable => false, :index => true
  property :number_of_centers, Integer, :nullable => false, :index => true
  property :in_operation_since, Date, :nullable => false, :index => true, :default => Date.new(2000, 1, 1)

  property :number_of_past_days, Integer, :nullable => true, :index => true, :default => 5
  property :min_date_from, Enum.send('[]', *MinDateFrom.keys), :nullable => true, :index => true, :default => :in_operation_since

  property :number_of_future_transaction_days, Integer, :nullable => true, :index => true, :default => 0

  property :number_of_future_days, Integer, :nullable => true, :index => true, :default => 100

  property :date_box_editable, Boolean, :default => true, :index => true

  property :email, String, :nullable => false, :index => true, :format => :email_address
  property :created, Boolean, :nullable => false, :index => true, :default => false
  property :color, String, :nullable => true
  property :logo_name,  String, :nullable => true
  property :date_format, Enum.send('[]', *DateFormats), :nullable => true, :index => true
  property :accounting_enabled, Boolean, :default => false, :index => true

  property :main_text, Text, :nullable => true, :lazy => true
  validates_length :name, :min => 3, :max => 20
  before :valid?, :save_image
  
  def self.first
    if $globals and $globals[:mfi_details] and $globals[:mfi_details].fetched==Date.today
      $globals[:mfi_details]
    elsif File.exists?(File.join(Merb.root, "config", "mfi.yml"))
      mfi = Mfi.new(YAML.load(File.read(File.join(Merb.root, "config", "mfi.yml"))))
      mfi.fetched = Date.today
      $globals ||= {}      
      $globals[:mfi_details] = mfi
      Misfit::Config::DateFormat.compile
      return mfi
    else      
      mfi = Mfi.new(:name => "Mostfit", :fetched => Date.today)
      Misfit::Config::DateFormat.compile
      return mfi
    end
  end
  
  def save
    $globals ||= {}
    $globals[:mfi_details] = Mfi.new(self.attributes)
    self.in_operation_since = self.in_operation_since.strftime("%Y-%m-%d")
    File.open(File.join(Merb.root, "config", "mfi.yml"), "w"){|f|
      f.puts self.to_yaml
    }
    Misfit::Config::DateFormat.compile
  end

  def save_image
    if self.logo[:filename] and not self.logo[:filename].blank? and ["image/jpeg", "image/png", "image/gif"].include?(self.logo[:content_type])      
      File.makedirs(File.join(Merb.root, "public", "images", "logos"))
      FileUtils.mv(self.logo[:tempfile].path, File.join(Merb.root, "public", "images", "logos", self.logo[:filename]))
      File.chmod(0755, File.join(Merb.root, "public", "images", "logos", self.logo[:filename]))
      self.logo_name = self.logo[:filename]
    end
  end
end
