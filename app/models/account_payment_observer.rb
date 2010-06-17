class AccountPaymentObserver
  include DataMapper::Observer
  observe Payment
  
  def self.make_posting_entries(obj, type)
  # This function will make entries to the posting database when save, update or delete envent triggers  
    if obj
      attributes = obj.attributes
      Journal.transaction do |t|       
        begin
          credit_account, debit_account = RuleBook.get_accounts(obj)
          journal = Journal.new(:comment => "Payment: #{obj.payment_type} - #{obj.amount}", 
                                :date => obj.received_on
                                :transaction_id => obj.id, :created_at => Time.now)
          journal.save      
          
          post = Posting.new(:amount => obj.amount * -1, :journal_id => journal.id, :account => debit_account,
                             :currency_id => 1)
          post.save
          
         
          post = Posting.new(:amount => obj.amount, :journal_id => journal.id, :account => credit_account,
                             :currency_id => 1)
          post.save
        rescue
          t.rollback
        end
      end
    end
  end
 
  after :create do
   AccountPaymentObserver.make_posting_entries(self)
  end  
    
  before :destroy do
    AccountPaymentObserver.get_object_state(self, :destroy) if not self.new?
  end

  after :destroy do
    AccountPaymentObserver.reverse_posting_entries(self)
  end
end
