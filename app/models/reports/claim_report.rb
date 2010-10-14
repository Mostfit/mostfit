class ClaimReport < Report
  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def self.name
    "Claim Report "
  end

  def generate
    branches, centers, claims = {}, {}, {}
    params = {:claim_submission_date.gte => from_date, :claim_submission_date.lte => to_date, :order => [:claim_submission_date]}
    Claim.all(params) + Claim.all(:claim_submission_date => nil, :order => [:claim_submission_date])
    Claim.all.group_by{ |claim| claim.client.center.branch} 
  end
end
