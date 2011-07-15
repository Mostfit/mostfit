class CreditAccountRule
  include DataMapper::Resource
  property :id, Serial
  property :rule_book_id, Integer  
  property :account_id,   Integer
  property :percentage,   Float, :nullable => false, :default => 100

  belongs_to :rule_book
  belongs_to :credit_account, Account

  # Returns amount to be credited and whether amount can be changed or not.
  # amounts are changable to counter the fact that VAR not identified right now
  def amount(date)
    case self.rule_book.action.to_sym
    when :disbursement
      amount = Loan.all("client.center.branch_id" => self.rule_book.branch.id, :disbursal_date => date, :rejected_on => nil).aggregate(:amount.sum) || 0
    when :principal
      amount = Payment.all("client.center.branch_id" => self.rule_book.branch.id, :type => :principal, :received_on => date).aggregate(:amount.sum) || 0
      advance = LoanHistory.sum_advance_payment(date, date, :branch, ["branch_id = #{self.rule_book.branch.id}"]).first
      if advance.nil?
        amount
      else
        amount -= advance.advance_principal.to_f
      end
    when :interest
      amount = Payment.all("client.center.branch_id" => self.rule_book.branch.id, :type => :interest, :received_on => date).aggregate(:amount.sum) || 0
      advance = LoanHistory.sum_advance_payment(date, date, :branch, ["branch_id = #{self.rule_book.branch.id}"]).first
      advance_interest  = advance ? (advance.advance_total - advance.advance_principal).to_f : 0
      if advance_interest == 0
        amount
      else
        amount -= advance_interest
      end
    when :fees
      amount = Payment.all("client.center.branch_id" => self.rule_book.branch.id, :type => :fees, :fee => self.rule_book.fee, :received_on => date).aggregate(:amount.sum) || 0
    when :advance_principal
      advance = LoanHistory.sum_advance_payment(date, date, :branch, ["branch_id = #{self.rule_book.branch.id}"]).first
      amount  = advance ? advance.advance_principal.to_f : 0
    when :advance_interest
      advance = LoanHistory.sum_advance_payment(date, date, :branch, ["branch_id = #{self.rule_book.branch.id}"]).first
      amount  = advance ? (advance.advance_total - advance.advance_principal).to_f : 0
    when :advance_principal_adjusted
      amount = advance_adjustment(:principal, date)
    when :advance_interest_adjusted
      amount = advance_adjustment(:total, date) - advance_adjustment(:principal, date)
    end

    # subtract the amount for which the posting has already been made
    amount = amount * percentage / 100.0
    journals = self.rule_book.journals(date)
    amount  -= (journals.postings(:account_id => self.credit_account_id, :fee_id => self.rule_book.fee_id, :action => self.rule_book.action).aggregate(:amount.sum) || 0).abs if journals
    amount.round(2) #[(amount > 0 ? amount : 0), false]
  end

  private
  def advance_adjustment(ptype, date)    
    advance_balance     = LoanHistory.advance_balance(date, :branch, ["branch_id = #{self.rule_book.branch.id}"]).first
    advance_old_balance = LoanHistory.advance_balance(date - 1, :branch, ["branch_id = #{self.rule_book.branch.id}"]).first
    advance_collected   = LoanHistory.sum_advance_payment(date, date, :branch, ["branch_id = #{self.rule_book.branch.id}"]).first
    
    #Formula for advance adjusted : adjusted  = old_balance - balance_today + collected_advance
    amount = ((advance_old_balance ? advance_old_balance.send("balance_#{ptype}") : 0) - (advance_balance ? advance_balance.send("balance_#{ptype}") : 0) + (advance_collected ? advance_collected.send("advance_#{ptype}") : 0)).to_f
  end

end
