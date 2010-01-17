class Mfi
  include DataMapper::Resource
  def self.default_repository_name 
    :abstract 
  end 

  attr_accessor :subdomain, :city_name, :state_id, :district_id

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
end
