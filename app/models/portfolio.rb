class Portfolio
  include DataMapper::Resource
  attr_accessor :centers

  before :destroy, :verified_cannot_be_deleted
  after  :save,    :process_portfolio_details
  after  :save,    :update_portfolio_value
  
  property :id, Serial
  property :name, String, :index => true, :nullable => false, :length => 3..20
  property :funder_id, Integer, :index => true, :nullable => false
  property :start_value, Float, :nullable => true
  property :outstanding_value, Float, :nullable => true
  property :principal_repaid, Float, :nullable => true
  property :interest_repaid, Float, :nullable => true
  property :fees_repaid, Float, :nullable => true
  property :last_payment_date, Date, :nullable => true
  property :outstanding_calculated_on, DateTime, :nullable => true
  property :verified_by_user_id,            Integer, :nullable => true, :index => true
  property :created_by_user_id,  Integer, :nullable => false, :index => true

  property :created_at, DateTime, :default => Time.now
  property :updated_at, DateTime, :default => Time.now

  belongs_to :funder
  has n, :portfolio_loans
  has n, :loans, :through => :portfolio_loans
  belongs_to :created_by,  :child_key => [:created_by_user_id],   :model => 'User'

  validates_is_unique :name
  belongs_to :verified_by, :child_key => [:verified_by_user_id], :model => 'User'
  validates_with_method :verified_by_user_id, :method => :verified_cannot_be_deleted, :when => [:destroy]

  def eligible_loans
    centers_hash = {}
    Center.all(:fields => [:id, :name]).each{|c| centers_hash[c.id] = c}
    
    hash = self.new? ? {} : {:portfolio_id.not => id}
    pids = (PortfolioLoan.all(hash).map{|x| x.loan_id})
    taken_loans = []
    if pids.length > 0
      taken_loans << "l.id not in (#{pids.join(', ')})"
    end

    data = LoanHistory.sum_outstanding_grouped_by(Date.today, [:center, :branch], taken_loans).group_by{|x| x.branch_id}.map{|bid, centers| 
      [Branch.get(bid), centers.group_by{|x| x.center_id}.map{|cid, rows| [centers_hash[cid], rows.first]}.to_hash]
    }.to_hash
  end

  def process_portfolio_details
    if centers and centers.length>0
      outstanding_statuses = [:outstanding, :disbursed]
      loans = []
      loan_values = {}
      existing_loans = self.loans.map{|l| l.id}
      self.loans.each{|l| l.history_disabled = true}
      
      centers = Center.all(:id => self.centers.reject{|cid, status| status != "on"}.keys)
      LoanHistory.loans_outstanding_for(centers).each{|loan|
        unless existing_loans.include?(loan.loan_id)
          PortfolioLoan.create!(:loan_id => loan.loan_id, :original_value => loan.amount, :added_on => Date.today, :portfolio => self,
                                :starting_value => loan.actual_outstanding_principal, :current_value => loan.actual_outstanding_principal)
        end
      }
      total_start_value = portfolio_loans.aggregate(:starting_value.sum) || 0
      repository.adapter.execute("UPDATE portfolios SET start_value=#{total_start_value}, outstanding_calculated_on=NOW() WHERE id=#{self.id}")
      return true
    end
  end
  
  def update_portfolio_value
    loan_values = {}
    # force reloading to read associations correctly
    self.reload
    loan_ids = []
    if PortfolioLoan.all(:portfolio_id => self.id).count > 0
      LoanHistory.loans_outstanding_for(self.loans(:fields => [:id])).each{|loan|
        loan_values[loan.loan_id] = loan
      }
      self.portfolio_loans.each{|l|
        next unless loan_values.key?(l.loan_id)
        l.current_value = loan_values[l.loan_id].actual_outstanding_principal
        l.save!
        loan_ids << l.loan_id
      }
    end
    if loan_ids.length > 0
      last_payment = Payment.all(:loan_id => loan_ids).max(:received_on)
      outstanding_value = portfolio_loans.aggregate(:current_value.sum) || 0
      repository.adapter.execute(%Q{
                                     UPDATE portfolios SET outstanding_value=#{outstanding_value}, outstanding_calculated_on=NOW(), last_payment_date='#{last_payment.strftime('%Y-%m-%d')}'
                                     WHERE id=#{self.id}
                                 })
    end
  end

  def verified_cannot_be_deleted
    return true unless verified_by_user_id
    throw :halt
  end
end
