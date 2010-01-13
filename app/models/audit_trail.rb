class AuditTrail
  include DataMapper::Resource
  
  property :id,              Serial
  property :auditable_id,    Integer, :nullable => false
  property :auditable_type,  String,  :nullable => false, :length => 50
  property :message,         String
  property :action,          Enum[:create, :update, :delete],  :nullable => false
  property :changes,         Yaml, :length => 20000
  property :created_at,      DateTime
  property :type, Enum[:log, :warning, :error]
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
