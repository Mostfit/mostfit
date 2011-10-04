class ModelObserver
  include DataMapper::Observer
  
  ANOMALIES = [Client, Loan]
  
  observe *ModelEventLog::MODELS_UNDER_OBSERVATION
  
  def self.make_event_entry(obj, action)
    log = ModelEventLog.new
    log.obj2model_event_log(obj)
    log.event_accounting_action = :create if action == :create
    log.event_change = action
    log.event_changed_at = DateTime.now
    log.save
  end

  before :create do
    created_on = Date.new(self.created_at.year, self.created_at.month, self.created_at.mday)
    self.parent_org_guid = Organization.get_organization(created_on).org_guid if Organization.get_organization(created_on)
  end

  after :create do
    return false unless Mfi.first.event_model_logging_enabled
    ModelObserver.make_event_entry(self, :create)
  end

  after :update do
    return false unless Mfi.first.event_model_logging_enabled
    action = :update
    class_of_self = nil
    ANOMALIES.each{|x|
      class_of_self =  x.to_s.downcase.to_sym if self.is_a?(x)
    }
    unless class_of_self.nil?
      action = :destroy unless self.deleted_at.nil?
    end
    ModelObserver.make_event_entry(self, action)
  end

  after :destroy do
    return false unless Mfi.first.event_model_logging_enabled
    ModelObserver.make_event_entry(self, :destroy)
  end
end
