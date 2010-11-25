class Funder
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String, :length => 50, :nullable => false, :index => true
  property :user_id, Integer, :nullable => true, :index => true

  belongs_to :user, :nullable => true

  has n, :funding_lines
  has n, :portfolios  

  def self.catalog
    result = {}
    funder_names = {}
    Funder.all(:fields => [:id, :name]).each { |f| funder_names[f.id] = f.name }
    FundingLine.all(:fields => [:id, :amount, :interest_rate, :funder_id]).each do |funding_line|
      funder = funder_names[funding_line.funder_id]
      result[funder] ||= {}
      result[funder][funding_line.id] = "Rs. #{funding_line.amount} @ #{funding_line.interest_rate}%"
    end
    result
  end

  def completed_lines(date = Date.today)
    funding_lines.count(:conditions => ['last_payment_date < ?', date])
  end
  def active_lines(date = Date.today)
    funding_lines.count(:conditions => ['disbursal_date <= ? AND last_payment_date <= ?', date, date])
  end
  def total_lines(date = Date.today)
    funding_lines.count(:conditions => ['disbursal_date >= ?', date])
  end
  
  # this function gives out all the branches that are accessible to a funder
  def branches(hash={})
    ids  = []
    ids << LoanHistory.ancestors_of_portfolio(self.portfolios, Branch, :branch => hash) if self.portfolios.count > 0
    ids << LoanHistory.parents_where_loans_of(Branch, {:loan => {:funding_line_id => funding_lines.map{|x| x.id}}, :branch => hash}) if funding_lines.count>0
    Branch.all(:id => ids.flatten)
  end

  # this function gives out all the centers that are accessible to a funder
  def centers(hash={})
    ids = []
    ids << LoanHistory.ancestors_of_portfolio(self.portfolios, Center, :center => hash) if self.portfolios.count > 0
    ids << LoanHistory.parents_where_loans_of(Center, {:loan => {:funding_line_id => funding_lines.map{|x| x.id}}, :center => hash}) if funding_lines.count>0
    Center.all(:id => ids.flatten)
  end

  def client_groups(hash={})
    ids = []    
    ids << LoanHistory.ancestors_of_portfolio(self.portfolios, ClientGroup) if self.portfolios.count > 0
    ids << LoanHistory.parents_where_loans_of(Center, {:loan => {:funding_line_id => funding_lines.map{|x| x.id}}, :center => hash}) if funding_lines.count>0
    ClientGroup.all(:id => ids.flatten)
  end

  # this function gives out all the clients that are accessible to a funder
  def clients(hash={})
    ids = []
    ids << LoanHistory.ancestors_of_portfolio(self.portfolios, Client, :client => hash) if self.portfolios.count > 0
    loan_hash = {:funding_line_id => funding_lines.map{|x| x.id}, :fields => [:id]}
    loan_hash[:client_id] = hash[:id] if hash[:id]
    ids << Loan.all(loan_hash).map{|x| x.client_id} if funding_lines.count>0
    Client.all(:id => ids.flatten)
  end

  # this function gives out all the loans that are accessible to a funder
  def loans(hash={})
    ids = []
    hash[:funding_line_id] = funding_lines.map{|x| x.id}
    loan_hash = {:loan => {:id => hash[:id]}} if hash.key?(:id)
    ids = LoanHistory.ancestors_of_portfolio(self.portfolios, Loan, loan_hash||{}) if self.portfolios.count > 0
    Loan.all(hash) + Loan.all(:id => ids)
  end

  # this function gives out all the loan ids that are accessible to a funder
  def loan_ids(hash={})
    hash[:funding_line_id] = funding_lines.map{|x| x.id}
    hash[:fields] = [:id]
    loan_hash = {:loan => {:id => hash[:id]}} if hash.key?(:id)
    ids  = LoanHistory.ancestors_of_portfolio(self.portfolios, Loan, loan_hash||{})
    Loan.all(hash).map{|x| x.id} + ids
  end

  # this function gives out all the payments that are accessible to a funder
  def payments(hash={})
    Loan.all(:funding_line_id => funding_lines.map{|x| x.id}).payments(hash) + Loan.all(:fields => [:id], :id => self.portfolios_loans.map{|x| x.loan_id}).payments(hash)
  end

  def staff_members(hash={})
    if hash[:id]
      ids  = branches.map{|x| x.manager_staff_id}
      ids += centers.map{|x| x.manager_staff_id}
      hash[:id] = [hash[:id]].flatten & ids
    else
      hash[:id]  = []
      hash[:id] += branches.map{|x| x.manager_staff_id}
      hash[:id] += centers.map{|x| x.manager_staff_id}
    end
    StaffMember.all(hash)
  end

  def funders(hash={})
    hash[:id] = self.id
    Funder.all(hash)
  end
end
