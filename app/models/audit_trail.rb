class AuditTrail
  include DataMapper::Resource
  
  property :id,              Serial
  property :auditable_id,    Integer, :nullable => false
  property :auditable_type,  String,  :nullable => false, :length => 50
  property :user_name,       String,  :nullable => false  # the user name will not change often
#  property :message,         String,  :nullable => false
  property :action,          String,  :nullable => false, :length => 50
  property :changes,         Yaml, :length => 20000
#  property :version,         Integer, :nullable => false, :default => 0
  property :created_at,      DateTime

  belongs_to :user

  def trail_for(obj, limit = nil)
    attrs = {
      :auditable_type => obj.class.to_s,
      :auditable_id => obj.id,
      :order => [:created_at.desc] }
    attrs.merge!(:limit => limit) if limit
    self.all(attrs)
  end
end
