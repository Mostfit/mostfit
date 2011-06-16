class AccountBalance
  include DataMapper::Resource
  
  before :save, :convert_blank_to_nil
  property :id, Serial

  property :opening_balance, Float
  property :closing_balance, Float
  property :created_at, DateTime
  property :verified_on, DateTime
  property :verified_by_user_id,            Integer, :nullable => true, :index => true
  property :accounting_period_id, Integer, :key => true
  property :account_id, Integer, :key => true
  belongs_to :verified_by, :child_key => [:verified_by_user_id], :model => 'User'

  validates_with_method :verified_on, :method => :properly_verified
  validates_with_method :verified_by_user_id, :method => :verified_cannot_be_deleted, :when => [:destroy]
  validates_with_method :verification_done_sequentially

  belongs_to :accounting_period
  belongs_to :account

  def verified?
    return true if (verified_by and verified_on)
    return false
  end

  def verified_cannot_be_deleted
    return true unless verified_by_user_id
    throw :halt
  end


  def properly_verified
    return true if ((not verified_on) and (not verified_by)) # not verified
    return true if (verified_on and verified_by)
    return [false, "Cannot be verified before the accounting period end date #{accounting_period.end_date}"] if verified_on < accounting_period.end_date
    return [false, "Both verification date and verifying staff member have to be chosen"] if not (verified_on and verified_by)
  end


  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.send(k).type==Float
        self.send("#{k}=", nil)
      end
    }
  end

  def verification_done_sequentially
    return true unless self.verified?
    previous_account_balances = AccountBalance.all(:account => account).collect{|x| x if x.accounting_period.end_date < self.accounting_period.begin_date}.delete_if{|x| x.nil?}
    previous_account_balances.each{|pab|
      return [false, "Previous account(s) not verified"] unless pab.verified?
    }
    return true
  end
end
