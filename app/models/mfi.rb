class Mfi
  include DataMapper::Resource
  DateFormats = ["%d-%m-%Y", "%Y-%m-%d", "%Y-%d-%m", "%d/%m/%Y", "%m/%d/%Y", "%d-%m-%y", "%y-%m-%d", "%y-%d-%m", "%d/%m/%y", "%m/%d/%y", "%d %B, %Y", "%d %B, %Y", "%A, %d %B %Y", "%A, %d %m %Y"]

  def self.default_repository_name
    :abstract 
  end 

  attr_accessor :subdomain, :city_name, :state_id, :district_id, :logo

  property :id, Serial, :required => true, :index => true
  property :name, String, :required => true, :index => true
  property :address, Text, :required => true, :index => false
  property :website, String
  property :telephone, String, :required => true, :index => true
  property :number_of_clients, Integer, :required => true, :index => true
  property :number_of_branches, Integer, :required => true, :index => true
  property :number_of_centers, Integer, :required => true, :index => true
  property :in_operation_since, Date, :required => true, :index => true
  property :email, String, :required => true, :index => true, :format => :email_address
  property :created, Boolean, :required => true, :index => true, :default => false
  property :color, String, :required => false
  property :logo_name,  String, :required => false
  property :date_format, Enum.send('[]', *DateFormats), :required => false, :index => true
  validates_length :name, :min => 3, :max => 20
  before :valid?, :save_image
  
  def save
    $globals ||= {}
    $globals[:mfi_details] = self.attributes
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
