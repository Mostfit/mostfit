class ClientGroup
  include DataMapper::Resource
  before :valid?, :add_created_by_staff_member
  after :save, :sync_clients

  property :id,                Serial
  property :name,              String, :nullable => false
  property :number_of_members, Integer, :nullable => true, :min => 1, :max => 20, :default => 5
  property :code,              String, :length => 14, :nullable => false, :index => true
  property :created_by_staff_member_id,  Integer, :nullable => false, :index => true

  validates_is_unique   :code, :scope => :center_id
  validates_length      :code, :min => 1, :max => 14

  has n, :clients
  belongs_to :center, :nullable => false
  belongs_to :created_by_staff,  :child_key => [:created_by_staff_member_id], :model => 'StaffMember'
  validates_is_unique :name, :scope => :center_id
  validates_with_method :client_should_be_migratable

  has n, :cgts
  has n, :grts

  # TODO: we need some way of tracking the CGT and GRT for wach of these groups. One solution is:
  # has n, :cgts        has n, :grts
  # or do we need a state machine?

  def client_should_be_migratable
    if not self.new? and self.clients.count>0 and self.dirty_attributes.find{|k,v| k.name==:center_id}
      errors = []
      self.clients.map{|client|
        client.center = self.center
        errors << "<li>#{client.name} - #{client.errors.to_a.to_s}</li>" unless client.valid?
      }
      return [false, "<ul>#{errors}</ul>"] if errors.length>0
    end
    return true
  end

  def sync_clients
    return unless self.valid?
    Client.all(:client_group_id => self.id).each{|client|
      client.center = self.center
      client.save_self

      client.loans.each{|l|
        if [:rejected, :repaid, :written_off, :claim_settlement].include?(l.status)
          repository.adapter.execute("update loan_history set center_id=#{self.center.id}, client_group_id=#{self.id} where loan_id=#{l.id}")
        else
          l.update_history
        end
      }
    }
  end

  def self.from_csv(row, headers)
    center = Center.first(:code => row[headers[:center_code]])
    obj    = new(:name => row[headers[:name]], :center_id => center.id, :code => row[headers[:code]])
    [obj.save, obj]
  end

  def self.search(q, per_page=10)
    if /^\d+$/.match(q)
      all(:conditions => ["id = ? or code=?", q, q], :limit => per_page)
    else
      all(:conditions => ["code=? or name like ?", q, q+'%'], :limit => per_page)
    end
  end

  def add_created_by_staff_member
    if self.center and self.new?
      self.created_by_staff_member_id = self.center.manager_staff_id
    end
  end
end
