class ClosedLoanReport < Report
  attr_accessor :from_date,:to_date, :branch, :branch_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report for #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end
  
  def name
    "Loan Closed Report for #{@from_date} to #{@to_date}"
  end

  def self.name
    "Loan Closed Report"
  end
  
  def generate
    data = {}
    @branch.each{|branch|
      data[branch] ||= {}
    }

    LoanHistory.all(:branch => @branch, :status => [:repaid, :written_off], :date.gte => @from_date, :date.lte => @to_date).each{|lh|
      status = if lh.status == :repaid and lh.amount_in_default < 0
                 'Foreclosure'
               elsif lh.status == :repaid
                 'Repaid'
               elsif lh.status == :written_off
                 'Written off'
               else
                 status = lh.status.to_s
               end
      data[lh.branch][lh.center] ||= []
      data[lh.branch][lh.center].push([lh.loan_id, lh.client_group != nil ? lh.client_group.name : "no group", lh.client.name, lh.loan.amount, status])

    }    

    # claim settlement
    client_ids = Claim.all(:claim_submission_date.gte => @from_date, :claim_submission_date.lte => @to_date, :order => [:id]).aggregate(:client_id)
    
    Loan.all(:client_id => client_ids, "client.center.branch_id" => @branch.map{|b| b.id}).each{|loan|
      center = loan.client.center
      branch = center.branch
      data[branch][center] ||= []
      data[branch][center].push([loan.id, loan.client.client_group.name, loan.client.name, loan.amount, loan.client.inactive_reason.camelcase(' ')])
    }    
    return data
  end
  
end
