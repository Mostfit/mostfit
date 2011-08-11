class ModelObserver
  include DataMapper::Observer
  
  OBJECTS_UNDER_OBSERVATION = [Client, Loan, LoanProduct]
  ANOMALIES = [Client, Loan]
  
  observe *OBJECTS_UNDER_OBSERVATION
  
  def self.make_event_entry(obj, action)
    obj_class = nil
    OBJECTS_UNDER_OBSERVATION.each{|x|
      obj_class =  x.to_s.downcase.to_sym if obj.is_a?(x)
    }
    log = ModelEventLog.create(
                               :parent_org_guid => obj.parent_org_guid,
                               :parent_domain_guid => obj.parent_domain_guid,
                               :event_change => action, 
                               :event_changed_at => DateTime.now,
                               :event_on_type => obj_class,     
                               :event_on_id => obj.id,    
                               :event_on_name => ((obj.respond_to?(:name)) ? obj.name : nil),
                               :event_accounting_action => :allow, 
                               :event_accounting_action_effective_date => nil
                               )
  end

  before :create do
    created_on = Date.new(self.created_at.year, self.created_at.month, self.created_at.mday)
    self.parent_org_guid = Organization.get_organization(created_on)
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
