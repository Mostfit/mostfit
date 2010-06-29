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

    Journal.transaction do |t|      
      journal = Journal.new(:comment => "Loan: #{obj.client.name} - #{obj.amount}", 
                            :date => obj.disbursal_date, :transaction_id => obj.id, :created_at => Time.now)
      journal_saved  = journal.save      
      
      
      post = Posting.new(:amount => obj.amount * -1, :journal_id => journal.id, :account => debit_account,
                         :currency_id => 1)
      debit_saved = post.save
      
      
      post = Posting.new(:amount => obj.amount, :journal_id => journal.id, :account => credit_account,
                         :currency_id => 1)
      credit_saved = post.save
      
      # Rollback in case of any failure above.
      if not (credit_saved and debit_saved and journal_saved)
        t.rollback
      end
    end
  end
  
  
  def self.reverse_entry(obj)
    Journal.transaction do |t|       
      credit_account, debit_account = RuleBook.get_accounts(obj)
      
      journal = Journal.new(:comment => "Loan: #{obj.client.name} - #{obj.amount} - reverse entry", 
                            :date => obj.disbursal_date, :transaction_id => obj.id, :created_at => Time.now)
      journal_saved  = journal.save      
      
      
      post = Posting.new(:amount => obj.amount, :journal_id => journal.id, :account => debit_account,
                         :currency_id => 1)
      debit_saved = post.save
      
      
      post = Posting.new(:amount => obj.amount * -1, :journal_id => journal.id, :account => credit_account,
                         :currency_id => 1)
      credit_saved = post.save
      
      # Rollback in case of any failure above.
      if not (credit_saved and debit_saved and journal_saved)
        t.rollback
      end
    end
  end

  
  before :update do
    AccountLoanObserver.make_posting_entries_on_update(self)
  end  
  
  before :destroy do
    AccountLoanObserver.get_object_state(self, :destroy) if not self.new?
  end
  
  after :destroy do
    AccountLoanObserver.reverse_posting_entries(self)
  end
end
