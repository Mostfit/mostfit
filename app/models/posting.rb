class Posting
  include DataMapper::Resource
  
  before :create,  :unverify_account_balances
  ACTIONS = [
             'principal', 'interest', 'fees', 'disbursement', 'advance_principal',
             'advance_interest', 'advance_principal_adjusted', 'advance_interest_adjusted', 'journal'
            ]

  property :id,             Serial
  property :amount,         Float,   :index => true   
  property :journal_id,     Integer, :index => true  
  property :account_id,     Integer, :index => true  
  property :currency_id,    Integer, :index => true
  property :action,         Enum.send('[]', *ACTIONS), :nullable => true
#  property :effective_date, Date,    :nullable => false, :default => lambda{ |obj, p| (obj.journal.date if obj.journal)}
#  property :deleted_at,     ParanoidDateTime
  
  belongs_to :journal
  belongs_to :account
  belongs_to :currency
  belongs_to :fee,        Fee, :nullable => true
  validates_with_method :journal_date_of_posting_is_after_account_opening_date

  def reverse(journal_id)
    return false if journal_id.nil? || journal_id.is_a?(Hash) || journal_id.is_a?(Array) || journal_id.is_a?(String)
    Posting.create(:amount => -(self.amount), :journal_id => journal_id, :account => self.account, :currency => self.currency, :action => (self.action.nil? ? "journal" : self.action))
  end
  
  def journal_date_of_posting_is_after_account_opening_date
    return [false, "Account #{self.account.name} does not exists on this date"] if self.account.opening_balance_on_date > Journal.get(journal_id).date
    return true
  end

  def unverify_account_balances
    accounting_period = AccountingPeriod.all(:end_date.gte => self.journal.date)
    accounting_period.each do |ap|
      account_balance = AccountBalance.first(:account => self.account, :accounting_period => ap)
      if account_balance and account_balance.verified?
        account_balance.verified_by = nil
        account_balance.verified_on = nil
        return [false, "Error, Account was not Un-Verfied"] unless account_balance.save
      end
    end
    return
  end

end


  
