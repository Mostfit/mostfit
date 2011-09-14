class ModelEventLog
  include DataMapper::Resource
  
  ACCOUNTING_ACTIONS = [:create, :allow_posting, :disallow_posting, :no_change]
  MODEL_CHANGES = [:create, :update, :destroy]
  # class.to_s.downcase.to_sym
  OBSERVED_MODELS = [:client, :loan, :loanproduct, :fee, :branch, :funder, :fundingline]
  MODELS_UNDER_OBSERVATION = [Client, Loan, LoanProduct, Branch]

  property :id,                                     Serial
  property :event_guid,                             String, :default => lambda{ |obj, p| UUID.generate }
  property :parent_org_guid,                        String
  property :parent_domain_guid,                     String         
  property :event_change,                           Enum.send('[]', *MODEL_CHANGES)
  property :event_changed_at,                       DateTime
  property :event_on_type,                          Enum.send('[]', *OBSERVED_MODELS)
  property :event_on_id,                            Integer
  property :event_on_name,                          String
  property :event_accounting_action,                Enum.send('[]', *ACCOUNTING_ACTIONS)
  property :event_accounting_action_effective_date, Date

  def obj2model_event_log(obj)
    obj_class = nil
    MODELS_UNDER_OBSERVATION.each{|x|
      obj_class =  x.to_s.downcase.to_sym if obj.is_a?(x)
    }
    event_log_attributes = {}
    obj_attributes = obj.attributes
    mapping ||= {
      :parent_org_guid => :parent_org_guid,
      :parent_domain_guid => :parent_domain_guid,
      :id => :event_on_id    
    }
    mapping.keys.each{|x| event_log_attributes[mapping[x]] = obj_attributes[x]}
    self.attributes = event_log_attributes
    self.event_on_name = ((obj.respond_to?(:name)) ? obj.name : nil)
    self.event_on_type = obj_class
    self.event_accounting_action = :allow_posting
    self.event_accounting_action_effective_date = nil
    return event_log_attributes
  end
  
  def to_xml(mel)
    block_of_code = Proc.new do
      mel.event_log{
        mel.event_log_guid                   self.event_guid 
        mel.change                           self.event_change.to_s                           
        mel.changed_at                       self.event_changed_at                       
        mel.on_type                          self.event_on_type.to_s                          
        mel.on_id                            self.event_on_id                            
        mel.on_name                          self.event_on_name                          
        mel.accounting_action                self.event_accounting_action.to_s                
        mel.accounting_action_effective_date self.event_accounting_action_effective_date
        mel.parent_org_guid                  self.parent_org_guid
        mel.parent_domain_guid               self.parent_domain_guid   
      }
    end
  return block_of_code
  end
end
