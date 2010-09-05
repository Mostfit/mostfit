class Funder
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String, :length => 50, :nullable => false, :index => true
  property :user_id, Integer, :nullable => true, :index => true

  belongs_to :user, :nullable => true

  has n, :funding_lines
  

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
    Branch.all(:id => LoanHistory.parents_where_loans_of(Branch, {:loan => {:funding_line_id => funding_lines.map{|x| x.id}}, :branch => hash}))
  end

  # this function gives out all the branches that are accessible to a funder
  def centers(hash={})
    Center.all(:id => LoanHistory.parents_where_loans_of(Center, {:loan => {:funding_line_id => funding_lines.map{|x| x.id}}, :center => hash}))
  end

  def client_groups(hash={})
    ClientGroup.all(:id => LoanHistory.parents_where_loans_of(ClientGroup, {:loan => {:funding_line_id => funding_lines.map{|x| x.id}}, :client_group => hash}))
  end

  # this function gives out all the branches that are accessible to a funder
  def clients(hash={})
    Client.all(:id => LoanHistory.parents_where_loans_of(Client, {:loan => {:funding_line_id => funding_lines.map{|x| x.id}}, :client => hash}))
  end

  # this function gives out all the branches that are accessible to a funder
  def loans(hash={})
    hash[:funding_line_id] = funding_lines.map{|x| x.id}
    Loan.all(hash)
  end

  # this function gives out all the branches that are accessible to a funder
  def payments(hash={})    
    Loan.all(:funding_line_id => funding_lines.map{|x| x.id}).payments(hash)
  end

end
