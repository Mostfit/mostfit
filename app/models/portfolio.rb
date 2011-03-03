class Portfolio
  include DataMapper::Resource
  include DateParser

  attr_accessor :centers, :added_on, :branch_id, :disbursed_after, :displayed_centers

  before :destroy, :verified_cannot_be_deleted
  before :valid?,  :parse_dates
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

  def loans(hash={})
    hash[:id] = portfolio_loans(:active => true).map{|x| x.id}
    Loan.all(hash)
  end
  
  def portfolio_loans(hash={})
    hash[:portfolio_id] = self.id
    hash[:active] = true
    PortfolioLoan.all(hash)
  end
  
  def eligible_loans
    centers_hash = {}
    row = Struct.new(:loan_count, :actual_outstanding_principal)

    Center.all(:fields => [:id, :name]).each{|c| centers_hash[c.id] = c}
    
    hash = self.new? ? {} : {:portfolio_id.not => id}
    hash[:active] = true
    pids = (PortfolioLoan.all(hash).map{|x| x.loan_id})
    
    hash         = {:current => true, :loan_id => PortfolioLoan.all(:portfolio_id => self.id).map{|pl| pl.loan_id}, :status => [:repaid, :written_off, :claim_settlement]}
    hash[:branch_id] = self.branch_id  if self.branch_id and self.branch_id.to_i > 0
    repaid_loans = LoanHistory.all(hash)
    
    query = []    
    query << "l.id not in (#{pids.join(', ')})" if pids.length > 0
    query << "l.disbursal_date>='#{self.disbursed_after.strftime('%Y-%m-%d')}'" if self.disbursed_after and self.disbursed_after.is_a?(Date)
    query << "lh.branch_id = #{self.branch_id}" if self.branch_id and self.branch_id.to_i > 0

    date = self.added_on || Date.today

    data = LoanHistory.sum_outstanding_grouped_by(date, [:center, :branch], query).group_by{|x| x.branch_id}.map{|bid, centers| 
      [Branch.get(bid), centers.group_by{|x| x.center_id}.map{|cid, rows| [centers_hash[cid], rows.first]}.to_hash]
    }.to_hash

    repaid_loans.each{|lh|
      data[lh.branch][lh.center] ||= row.new(0, 0)
      data[lh.branch][lh.center].loan_count += 1
      data[lh.branch][lh.center].actual_outstanding_principal += lh.actual_outstanding_principal
    }
    data
  end

  def process_portfolio_details
    if centers and centers.length>0
      outstanding_statuses = [:outstanding, :disbursed]
      loan_values = {}
      accounted_for = []

      existing_loans = self.portfolio_loans.map{|l| l.loan_id}
      self.loans.each{|l| l.history_disabled = true}

      centers = Center.all(:id => self.centers.reject{|cid, status| status != "on"}.keys)
      inactive_loans = PortfolioLoan.all(:portfolio_id => self.id, :active => false, :fields => [:id, :loan_id]).map{|x| x.loan_id}
      self.added_on  = Date.parse(self.added_on) if self.added_on.is_a?(String)

      LoanHistory.loans_outstanding_for(centers, self.added_on).each{|loan|
        if existing_loans.include?(loan.loan_id)
          accounted_for << loan.loan_id
        elsif inactive_loans.include?(loan.loan_id)
          accounted_for << loan.loan_id
          pl = PortfolioLoan.first(:portfolio_id => self.id, :loan_id => loan.loan_id)
          pl.active = true
          pl.save
        else
          PortfolioLoan.create!(:loan_id => loan.loan_id, :original_value => loan.amount, :added_on => self.added_on, :portfolio => self,
                                :starting_value => loan.actual_outstanding_principal, :current_value => loan.actual_outstanding_principal)
        end
      }

      # deactivate all the loans which are not accounted for
      Loan.all(:id => (existing_loans - accounted_for), "client.center_id" => displayed_centers).each{|lid|
        if pl = PortfolioLoan.first(:loan_id => lid, :portfolio_id => self.id)
          pl.update(:active => false)
        end
      } if (existing_loans - accounted_for).length > 0

      total_start_value = portfolio_loans.aggregate(:starting_value.sum) || 0
      repository.adapter.execute("UPDATE portfolios SET start_value=#{total_start_value}, outstanding_calculated_on=NOW() WHERE id=#{self.id}")
      return true
    end
  end
  
  def update_portfolio_value
    loan_values = {}
    last_payment_created_at = Payment.all("loan.portfolio_loans.portfolio_id" => self.id).max(:created_at)
    return unless last_payment_created_at
    return if last_payment_created_at.new_offset <=  (self.updated_at + self.updated_at.offset).new_offset
    
    # force reloading to read associations correctly
    self.reload
    loan_ids = []

    if PortfolioLoan.all(:portfolio_id => self.id, :active => true).count > 0
      LoanHistory.loans_outstanding_for(Loan.all(:id => self.portfolio_loans.map{|x| x.loan_id}, :fields => [:id])).each{|loan|
        loan_values[loan.loan_id] = loan
      }
      self.portfolio_loans(:active => true).each{|l|
        if loan_values.key?(l.loan_id)
          l.current_value = loan_values[l.loan_id].actual_outstanding_principal
        else
          l.current_value = 0
        end
        l.save!
        loan_ids << l.loan_id
      }
    end

    if loan_ids.length > 0
      outstanding_value = portfolio_loans(:active => true).aggregate(:current_value.sum) || 0
      last_payment_date       = Payment.all("loan.portfolio_loans.portfolio_id" => self.id).max(:received_on)
      repository.adapter.execute(%Q{
                                     UPDATE portfolios SET outstanding_value=#{outstanding_value}, outstanding_calculated_on=NOW(), last_payment_date='#{last_payment_date.strftime('%Y-%m-%d')}', updated_at=NOW()
                                     WHERE id=#{self.id}
                                 })
    end
  end

  def verified_cannot_be_deleted
    return true unless verified_by_user_id
    throw :halt
  end
end
