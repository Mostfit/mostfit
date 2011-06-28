class Region
  include DataMapper::Resource
  property :id, Serial
  property :name, Text
  property :address,              Text,   :lazy => true
  property :contact_number,       String, :length => 40, :lazy => true
  property :landmark,             String, :length => 100, :lazy => true  
  property :creation_date,        Date,   :length => 100, :lazy => true, :default => Date.today

  has n, :areas
  belongs_to :manager, :model => "StaffMember"

  validates_present :manager, :message => I18n.t("region.error.validation.manager_not_present", :default => "Manager must not be blank")
  validates_is_unique :name, :message =>  I18n.t("region.error.validation.name_not_unique", :default => "Name must be unique")
  max_name_length = 20
  min_name_length = 1
  validates_length :name, :max => max_name_length, :min => min_name_length, 
                   :message =>  I18n.t("region.error.validation.name_length", :max => max_name_length, :min => min_name_length, 
                   :default => "Name must be between #{min_name_length} and #{max_name_length} characters long")

  def location
    Location.first(:parent_id => self.id, :parent_type => "region")
  end

end
