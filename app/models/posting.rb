class Posting
  include DataMapper::Resource
  
  property :id,           Serial
  property :amount,       Float,   :index => true   
  property :journal_id,   Integer, :index => true  
  property :account_id,   Integer, :index => true  
  property :currency_id,  Integer, :index => true  
  belongs_to :journal
  belongs_to :account
  belongs_to :currency
  validates_with_method :journal_date_of_posting_is_after_account_opening_date
  
  def journal_date_of_posting_is_after_account_opening_date
    return [false, "Account #{@account.name} does not exists on this date"] if @account.opening_balance_on_date > Journal.get(journal_id).date
    return true
  end

end


  
