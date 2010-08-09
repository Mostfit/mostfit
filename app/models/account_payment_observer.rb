class AccountPaymentObserver
  include DataMapper::Observer
  observe Payment
  
  def self.make_posting_entries(obj)
    # This function will make entries to the posting database when save, update or delete envent triggers  
    credit_accounts, debit_accounts = RuleBook.get_accounts(obj)
    # do not do accounting if no matching accounts
    return unless (credit_accounts and debit_accounts)
    return unless (credit_accounts.length>=0 and debit_accounts.length>=0)
    
    journal = {:date => obj.received_on, :transaction_id => obj.id.to_s, :currency => Currency.first, :amount => obj.amount}
    journal[:comment] = "Payment: #{obj.type} - #{obj.amount}"
    if obj.type == 'fees' or obj.type == 'interest' or obj.type == 'principal'
      journal[:journal_type_id]=  2
    else
      journal[:journal_type_id]=  3
    end
    status, @journal = Journal.create_transaction(journal, debit_accounts, credit_accounts)
  end

  def self.single_voucher_entry(payments)
    obj = payments.first   
    # This function will make entries to the posting database when save, update or delete envent triggers  
    credit_accounts, debit_accounts = RuleBook.get_accounts(payments)
    # do not do accounting if no matching accounts
    return unless (credit_accounts and debit_accounts)
    return unless (credit_accounts.length>=0 and debit_accounts.length>=0)
    
    journal = {:date => obj.received_on, :transaction_id => obj.id.to_s, :currency => Currency.first}
    amount  = payments.map{|x| x.amount}.inject(0){|s,x| s+=x}
    client  = obj.client || obj.loan.client
    if client
      journal[:comment] = "Payment: #{client.name}"
    else
      journal[:comment] = "Payments: #{payments.map{|x| x.id}.join(',')}"
    end
    journal[:journal_type_id]=  2
    status, @journal = Journal.create_transaction(journal, debit_accounts, credit_accounts)
  end
  
  def self.reverse_posting_entries(obj)
    credit_accounts, debit_accounts = RuleBook.get_accounts(obj)
    # do not do accounting if no matching accounts
    return unless (credit_accounts and debit_accounts)
    return unless (credit_accounts.length>=0 and debit_accounts.length>=0)
    
    journal = {:date => obj.received_on, :transaction_id => obj.id.to_s, :currency => Currency.first, :amount => obj.amount * -1}
    journal[:comment] = "Payment: #{obj.type} - #{obj.amount}"

    #reverse the signs
    debit_accounts.each{|account, amount|  debit_accounts[account] = amount * -1}     if debit_accounts.is_a?(Hash)
    credit_accounts.each{|account, amount| credit_accounts[account] = amount * -1}    if credit_accounts.is_a?(Hash)
    
    if obj.type == 'fees' or obj.type == 'interest' or obj.type == 'principal'
      journal[:journal_type_id]=  2
    else
      journal[:journal_type_id]=  3
    end
    
    status, @journal = Journal.create_transaction(journal, debit_accounts, credit_accounts)
  end
  
  
  after :create do    
    AccountPaymentObserver.make_posting_entries(self) unless self.override_create_observer
  end  
  
  before :save do
    AccountPaymentObserver.reverse_posting_entries(self) unless deleted_at.nil?
  end
end
