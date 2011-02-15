class AssetRegister
  include DataMapper::Resource
  before :save, :convert_blank_to_nil
  
  property :id,              Serial
  property :name,            String,  :length => 100,         :nullable => false, :index => true
  property :asset_type,      String,  :length => 100,         :nullable => false
  property :issue_date,      Date,    :default => Date.today, :nullable => false
  property :returned_date,   Date,    :nullable => true
  property :issued_by,       String,  :length => 100
  property :branch_name,     String,  :nullable => true,      :index => true
  property :branch_id,       Integer, :nullable => false,     :index => true

  belongs_to  :manager,  :child_key => [:manager_staff_id],  :model => 'StaffMember'
  belongs_to  :branch,   :child_key => [:branch_id],         :model => 'Branch'

  validates_present       :manager
  validates_with_method   :manager,   :manager_is_an_active_staff_member?

  private
  def manager_is_an_active_staff_member?
    return true if manager and manager.active
    [false, "Managing staff member is currently not active"]
  end

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.properties.find{|x| x.name == k}.type==Integer
        self.send("#{k}=", nil)
      end
    }
  end
end
