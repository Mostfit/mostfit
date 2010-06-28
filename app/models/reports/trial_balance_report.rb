class TrialBalanceReport < Report
  attr_accessor :from_date, :to_date, :account, :account_id, :journal,:posting, :account_type_id

  def initialize(params,dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.min_date
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name      = "Trial Balance"
  #  @page      = params[:page] ||0
    get_parameters(params, user)
  end

  def name
    "Trial Balance"
  end

  def self.name
    "Trial Balance"
  end

  def generate(param)
  
    Account.paginate(:order => [:account_type_id.asc],:page =>param[:page],:per_page => 10) 
  end
end   

