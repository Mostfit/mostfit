class ModelEventLog
  include DataMapper::Resource
  
  ACTIONS = [:allow, :disallow]
  CHANGES = [:create, :update, :destroy]
  # .to_s.downcase.to_sym
  OBJECT = [:client, :loan, :loanproduct, :fee, :branch, :funder, :fundingline]
  
  property :id,                                     Serial
  property :event_guid,                             String, :default => lambda{ |obj, p| UUID.generate }
  property :event_change,                           Enum.send('[]', *CHANGES)
  property :event_changed_at,                       DateTime
  property :event_on_type,                          Enum.send('[]', *OBJECT)
  property :event_on_id,                            Integer
  property :event_on_name,                          String
  property :event_accounting_action,                Enum.send('[]', *ACTIONS)
  property :event_accounting_action_effective_date, Date

end
