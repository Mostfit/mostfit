class PaymentObserver
  include DataMapper::Observer
  
  observe Payment

  # This function will make entries to the transaction database when save, update or delete event is triggered
  def self.make_transaction_entry(payment, action)
    transaction_log = TransactionLog.new()
    transaction_log.payment2transaction_log(payment)
    transaction_log.update_type = action
    transaction_log.save
  end

  # We are only observing the create and update methods because the payment model only uses these methods. 
  # In case of of a payment getting deleted the update function is called and then the save function is called. 
  
  # In case of a payment getting updated (i.e. some of the details of the payment are changed and then saved) then the current payment is deleted and a new copy with the updated details is saved with a new payment id

  before :create do
    self.parent_org_guid = Organization.get_organization(self.received_on).org_guid
  end
  
  after :create do
    return false unless Mfi.first.transaction_logging_enabled
    PaymentObserver.make_transaction_entry(self, :create)
  end

  after :update do
    return false unless Mfi.first.transaction_logging_enabled
    PaymentObserver.make_transaction_entry(self, :delete)
  end
  
end
