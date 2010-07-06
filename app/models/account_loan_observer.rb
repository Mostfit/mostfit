class AccountLoanObserver
  include DataMapper::Observer    
  observe Loan
  
  def self.make_posting_entries_on_update(obj)
    # This function will make entries to the posting database when save, update or delete event triggers  
   
    return false unless obj

    original_attributes = obj.original_attributes.map{|k,v| {k.name => v}}.inject({}){|s,x| s+=x}
    attributes = obj.attributes
    if    original_attributes[:disbursal_date].nil? and attributes[:disbursal_date].nil?
      return
    elsif original_attributes[:disbursal_date].nil? and attributes[:disbursal_date]
      self.forward_entry(obj)
    elsif original_attributes[:disbursal_date]      and attributes[:disbursal_date].nil?
      self.reverse_entry(obj)
    elsif attributes[:disbursal_date] != original_attributes[:disbursal_date]
      self.reverse_entry(obj)
      self.forward_entry(obj)
    end
    
    if original_attributes[:amount] != attributes[:amount]
          
    end
  end
  
  def self.forward_entry(obj)
    credit_account, debit_account = RuleBook.get_accounts(obj)
    # do not do accounting if no matching accounts
    return unless (credit_account and debit_account)
    journal = {:date => obj.disbursal_date, :transaction_id => obj.id.to_s, :currency => Currency.first, :amount => obj.amount}
    journal[:comment] = "Loan: #{obj.client.name} - #{obj.amount}"
    journal[:journal_type_id] = 1
    status, @journal = Journal.create_transaction(journal, debit_account, credit_account)
  end
  
  def self.reverse_entry(obj)
    credit_account, debit_account = RuleBook.get_accounts(obj)
    # do not do accounting if no matching accounts
    return unless (credit_account and debit_account)
    journal = {:date => obj.disbursal_date, :transaction_id => obj.id.to_s, :currency => Currency.first, :amount => (obj.amount * -1)}
    journal[:comment] = "Loan: #{obj.client.name} - #{obj.amount} - reverse entry"
    journal[:journal_type_id] = 1
    status, @journal = Journal.create_transaction(journal, debit_account, credit_account)
  end
  
  before :update do
    AccountLoanObserver.make_posting_entries_on_update(self)
  end  
  
  after :destroy do
    AccountLoanObserver.reverse_posting_entries(self)
  end
end
