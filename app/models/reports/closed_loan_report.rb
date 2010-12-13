class ClosedLoanReport < Report


  attr_accessor :from_date,:to_date

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
    @data ={}
    @branch = Branch.all.map{ |b| [b.id,b.name]}.to_hash
    @center = Center.all.map{ |c| [c.id,c.name]}.to_hash
    @client_group = ClientGroup.all.map{ |cg| [cg.id,cg.name]}.to_hash
    @client = Client.all.map{|cl| [cl.id,cl.name]}.to_hash
    @loan = Loan.all.map{|l| [l.id,l.amount]}.to_hash
   
    lh = LoanHistory.all(:status => :repaid, :date.gte => @from_date, :date.lte => @to_date) + LoanHistory.all(:status => :written_off, :date.gte => @from_date, :date.lte => @to_date) + LoanHistory.all(:amount_in_default.lt => 0, :date.gte => @from_date, :date.lte => @to_date) 
    
    lh.each{ |a|
      @data[a]||={}      
      @data[a][0] = @branch[a.branch_id]
      @data[a][1] = @center[a.center_id]
      @data[a][2] = @client_group[a.client_group_id]
      @data[a][3] = @client[a.client_id]
      @data[a][4] = @loan[a.loan_id]

      status =  a.status.to_s
      
      if status == 'repaid'
        @data[a][5] = 'Repayment'
      elsif status == 'written_off'
        @data[a][5] = 'Written off'
      elsif a.amount_in_default < 0
        @data[a][5] = 'Foreclosure'
      end
    }
    
    claims = Claim.all(:claim_submission_date.gte => @from_date, :claim_submission_date.lte => @to_date)
    
    claims.each{ |c|
      @data[c]||={}
      @data[c][0] = @branch[c.client.center.branch_id]
      @data[c][1] = @center[c.client.center_id]
      @data[c][2] = @client_group[c.client.client_group_id]
      @data[c][3] = @client[c.client_id]
      c.client.loans.each do |l|
        @data[c][4] = l.amount
      end
      @data[c][5] = 'Insurance Claim after death'
    }
    return @data
  end
  
end
