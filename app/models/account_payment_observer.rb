class AccountPaymentObserver
  include DataMapper::Observer
  observe BranchDiary

  def self.make_posting_entries(obj)
    # This function will make entries to the posting database when save, update or delete envent triggers  
    credit_accounts, debit_accounts, rules = RuleBook.get_accounts(obj)
    # do not do accounting if no matching accounts
    return unless (credit_accounts and debit_accounts)
    return unless (credit_accounts.length>=0 and debit_accounts.length>=0)
    
    journal = {:date => obj.received_on, :transaction_id => obj.id.to_s, :currency => Currency.first, :amount => obj.amount}
    journal[:comment] = "Payment: #{obj.type} - #{obj.amount}"

    journal[:journal_type_id]=  2

    status, @journal = Journal.create_transaction(journal, debit_accounts, credit_accounts, rules)
  end

  def self.single_voucher_entry(payments)
    obj = payments.first
    # This function will make entries to the posting database when save, update or delete envent triggers  
    credit_accounts, debit_accounts, rules = RuleBook.get_accounts(payments)
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
    journal[:journal_type_id]=  rules.first.journal_type.id
    status, @journal = Journal.create_transaction(journal, debit_accounts, credit_accounts, rules)
  end
  
  def self.reverse_posting_entries(obj)
    credit_accounts, debit_accounts, rule = RuleBook.get_accounts(obj)
    # j = Journal.first(:transaction_id => obj.id, :journal_type_id => 1, :order => [:created_at.desc]) if obj.type == :principal
    # j = Journal.first(:transaction_id => obj.id, :journal_type_id => 2, :order => [:created_at.desc]) if obj.type == :interest or obj.type == :fees
    # credit_accounts, debit_accounts  = {}, {}
    # j.postings.each{|p|
    #   credit_accounts[p.account] = p.amount if p.amount >= 0
    #   debit_accounts[p.account] = p.amount * -1 if p.amount < 0 #we keep every amount positive here, similar to forward entry. Rest is taken care off later.
    # }

    # do not do accounting if no matching accounts
    return unless (credit_accounts and debit_accounts)
    return unless (credit_accounts.length>=0 and debit_accounts.length>=0)
    journal = {:date => obj.received_on, :transaction_id => obj.id.to_s, :currency => Currency.first, :amount => obj.amount * -1}
    journal[:comment] = "Payment: #{obj.type} - #{obj.amount} - Reverse entry"

    #reverse the signs
    debit_accounts.each{|r, val|  val.each{|account, amount| val[account] = amount * -1}}     if debit_accounts.is_a?(Hash)
    credit_accounts.each{|r, val| val.each{|account, amount| val[account] = amount * -1}}    if credit_accounts.is_a?(Hash)
    
    journal[:journal_type_id]=  rule.journal_type.id
    status, @journal = Journal.create_transaction(journal, debit_accounts, credit_accounts)
  end
  
  
  after :create do    
    AccountPaymentObserver.make_posting_entries(self) unless self.override_create_observer
  end  
  
  before :save do
    AccountPaymentObserver.reverse_posting_entries(self) unless deleted_at.nil?
  end
end
