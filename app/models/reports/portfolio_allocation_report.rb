class PortfolioAllocationReport < Report
  attr_accessor :funder, :funder_id
  
  def initialize(params, dates, user)
    @name   = "Portfolio Allocation Report: #{@funder}"    
    get_parameters(params, user)
  end
  
  def name
    "Portfolio Allocation Report"
  end
  
  def self.name
    "Portfolio Allocation Report"
  end
  
  def generate
    data = {}
    funders = {}
    Funder.all.each{|f| funders[f.id]=(f.portfolios.aggregate(:id, :name, :funder_id, :start_value,
                                                              :outstanding_value, :created_at).map{|y| [y[0], y[1], y[2], y[3], y[4], y[5]]})}
    
    if @funder
      data[@funder] = funders[@funder.id]
    else
      Funder.all.each do |x|
	data[x] = funders[x.id]
      end
    end
    return data
  end
end
