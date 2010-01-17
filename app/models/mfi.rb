DataMapper.setup(:abstract, "abstract::")    
class Mfi
  include DataMapper::Resource
  attr_accessor :subdomain

  property :id, Serial, :nullable => false, :index => true
  property :name, String, :nullable => false, :index => true
  property :address, Text, :nullable => false, :index => false
  property :website, String
  property :telephone, String, :nullable => false, :index => true
  property :number_of_clients, Integer, :nullable => false, :index => true
  property :number_of_branches, Integer, :nullable => false, :index => true
  property :number_of_centers, Integer, :nullable => false, :index => true
  property :in_operation_since, Date, :nullable => false, :index => true
  property :email, String, :nullable => false, :index => true, :format => :email_address
  property :created, Boolean, :nullable => false, :index => true, :default => false
  property :color, String, :nullable => true
  property :logo,  String, :nullable => true

  validates_length :name, :min => 3, :max => 20
  before :valid?, :save_image

  def save_image
    if self.logo[:filename] and ["image/jpeg", "image/png", "image/gif"].include?(self.logo[:content_type])      
      File.makedirs(File.join(Merb.root, "public", "images", "logos"))
      FileUtils.mv(self.logo[:tempfile].path, File.join(Merb.root, "public", "images", "logos", self.logo[:filename]))
      self.logo = self.logo[:filename]
    end
  end
  
  def self.default_repository_name 
    :abstract 
  end 

  def not_in_barred_list
    if BARRED_DOMAINS.include?(self.subdomain)
      return [false, "Sorry! This subdomain name cannot be used"]
    elsif not /^[a-z.A-Z0-9]*$/.match(self.subdomain)
      return [false, "Sorry! The subdomain is not valid. Sudomain can only have alphabets, numbers and dots"]
    else
      return true
    end
  end
  
  def set_state_id
    if district_id and district = District.get(district_id)
      self.state_id  =  district.state_id
    else
      self.state_id  = 0
    end
  end  
end
