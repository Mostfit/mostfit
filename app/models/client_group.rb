class ClientGroup
  include DataMapper::Resource
  
  property :id,                Serial
  property :name,              String, :nullable => false
  property :number_of_members, Integer, :nullable => true, :min => 1, :max => 20, :default => 5
  property :code,              String, :length => 14, :nullable => false, :index => true

  validates_is_unique   :code, :scope => :center_id
  validates_length      :code, :min => 1, :max => 14

  has n, :clients
  belongs_to :center
  validates_is_unique :name, :scope => :center_id  

  def self.search(q)
    if /^\d+$/.match(q)
      all(:conditions => ["id = ? or code=?", q, q])
    else
      all(:conditions => ["code=? or name like ?", q, q+'%'])
    end
  end
  

end
