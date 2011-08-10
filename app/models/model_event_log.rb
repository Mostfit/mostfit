class ModelEventLog
  include DataMapper::Resource
  
  ACCOUNTING_ACTIONS = [:allow, :disallow, :no_change]
  CHANGES = [:create, :update, :destroy]
  # class.to_s.downcase.to_sym
  OBSERVED_MODELS = [:client, :loan, :loanproduct, :fee, :branch, :funder, :fundingline]
  
  property :id,                                     Serial
  property :event_guid,                             String, :default => lambda{ |obj, p| UUID.generate }
  property :event_change,                           Enum.send('[]', *MODEL_CHANGES)
  property :event_changed_at,                       DateTime
  property :event_on_type,                          Enum.send('[]', *OBSERVED_MODELS)
  property :event_on_id,                            Integer
  property :event_on_name,                          String
  property :event_accounting_action,                Enum.send('[]', *ACCOUNTING_ACTIONS)
  property :event_accounting_action_effective_date, Date

end
