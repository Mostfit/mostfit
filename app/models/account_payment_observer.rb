class AccountPaymentObserver
  include DataMapper::Observer
  observe Payment
  
  def self.make_posting_entries(obj)
    # This function will make entries to the posting database when save, update or delete envent triggers  
    credit_account, debit_account = RuleBook.get_accounts(obj)
    # do not do accounting if no matching accounts
    return unless (credit_account and debit_account)
    
    journal = {:date => obj.received_on, :transaction_id => obj.id.to_s, :currency => Currency.first, :amount => obj.amount}
    journal[:comment] = "Payment: #{obj.type} - #{obj.amount}"
    if obj.type == 'fees' or 'interest' or 'principal'
      journal[:journal_type_id]=  2
    else
      journal[:journal_type_id]=  3
    end
    status, @journal = Journal.create_transaction(journal, debit_account, credit_account)
  end
  
  def self.reverse_posting_entries(obj)
    credit_account, debit_account = RuleBook.get_accounts(obj)
    # do not do accounting if no matching accounts
    return unless (credit_account and debit_account)
    
    journal = {:date => obj.received_on, :transaction_id => obj.id.to_s, :currency => Currency.first, :amount => obj.amount * -1}
    journal[:comment] = "Payment: #{obj.type} - #{obj.amount}"
    
    if obj.type == 'fees' or 'interest' or 'principal'
      journal[:journal_type_id]=  2
    else
      journal[:journal_type_id]=  3
    end
    
    status, @journal = Journal.create_transaction(journal, debit_account, credit_account)
  end
  
  
  after :create do
    AccountPaymentObserver.make_posting_entries(self)
  end  
  
  before :save do
    AccountPaymentObserver.reverse_posting_entries(self) unless deleted_at.nil?
  end
end
