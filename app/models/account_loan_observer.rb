class AccountLoanObserver
  include DataMapper::Observer    
  observe Loan
  
  def self.get_state(obj)
    #needed for deep copy!
    @old_obj = obj.original_attributes.map{|k,v| {k.name => (k.lazy? ? obj.send(k.name) : v)}}.inject({}){|s,x| s+=x}
    @is_new = obj.new?
  end

  def self.make_posting_entries_on_update(obj)
    # This function will make entries to the posting database when save, update or delete event triggers  
    return false unless obj
    attributes = obj.attributes
    original_attributes = @old_obj
    if @is_new 
      #loan has just been created
      self.forward_entry(obj) if not attributes[:disbursal_date].nil? and not attributes[:amount].nil? 
      return
    end  

    return if not original_attributes.key?(:amount) and not original_attributes.key?(:disbursal_date)

    if original_attributes.key?(:disbursal_date) and original_attributes[:disbursal_date].nil? and attributes[:disbursal_date]
      #set
      self.forward_entry(obj)
    elsif original_attributes.key?(:disbursal_date) and not original_attributes[:disbursal_date].nil? and attributes[:disbursal_date].nil?
      #unset
      self.reverse_entry(obj, original_attributes)
    elsif (original_attributes.key?(:amount) and original_attributes[:amount] != attributes[:amount]) or (original_attributes.key?(:disbursal_date) and attributes[:disbursal_date] != original_attributes[:disbursal_date])
      #both are changing, or dd is chaging or amount is changing
      self.reverse_entry(obj, original_attributes)
      self.forward_entry(obj)           
    end
  end
  
  def self.forward_entry(obj)
    credit_account, debit_account = RuleBook.get_accounts(obj)
    # do not do accounting if no matching accounts
    return unless (credit_account and debit_account)
    journal = {:date => obj.disbursal_date, :transaction_id => obj.id.to_s, :currency => Currency.first, :amount => obj.amount}
    journal[:comment] = "Loan_id: #{obj.id}-Client:#{obj.client.name}"
    journal[:journal_type_id] = 1
    status, @journal = Journal.create_transaction(journal, debit_account, credit_account)
  end
  
  def self.reverse_entry(obj, old_attributes)
    credit_account, debit_account = RuleBook.get_accounts(obj)
    # do not do accounting if no matching accounts
    return unless (credit_account and debit_account)
    amount = old_attributes[:amount]||obj.amount
    date   = old_attributes[:disbursal_date]||obj.disbursal_date

    journal = {:date => date, :transaction_id => obj.id.to_s, :currency => Currency.first, :amount => (amount * -1)}
    journal[:comment] = "Loan_id: #{obj.id}-Client:#{obj.client.name} - reverse entry"
    journal[:journal_type_id] = 1
    status, @journal = Journal.create_transaction(journal, debit_account, credit_account)
  end
  
  before :save do 
    AccountLoanObserver.get_state(self)
  end

  after :save do
    AccountLoanObserver.make_posting_entries_on_update(self)
  end  
  
  after :destroy do
    AccountLoanObserver.reverse_posting_entries(self)
  end
end
