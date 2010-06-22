class AccountLoanObserver
  include DataMapper::Observer
  observe Loan
  

  def self.make_posting_entries_on_update(obj)
    # This function will make entries to the posting database when save, update or delete envent triggers  
    if obj
      if obj.disbursal_date and obj.approved_on
        Journal.transaction do |t|       
          credit_account, debit_account = RuleBook.get_accounts(obj)

          journal = Journal.new(:comment => "Loan: #{obj.discriminator} - #{obj.amount}", 
                                :transaction_id => obj.id, :created_at => Time.now)
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
    end
  end
    

  after :update do
    AccountLoanObserver.make_posting_entries_on_update(self)
  end  
  
  before :destroy do
    AccountLoanObserver.get_object_state(self, :destroy) if not self.new?
  end
  
  after :destroy do
    AccountLoanObserver.reverse_posting_entries(self)
  end
end
