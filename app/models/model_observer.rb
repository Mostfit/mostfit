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
                               :event_change => action, 
                               :event_changed_at => DateTime.now,
                               :event_on_type => obj_class,     
                               :event_on_id => obj.id,    
                               :event_on_name => ((obj.respond_to?(:name)) ? obj.name : nil),
                               :event_accounting_action => :allow, 
                               :event_accounting_action_effective_date => nil
                               )
  end

  after :create do
    ModelObserver.make_event_entry(self, :create)
  end

  after :update do
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
    ModelObserver.make_event_entry(self, :destroy)
  end
end
