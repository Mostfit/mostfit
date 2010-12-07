class ClosedLoanReport < Report


  attr_accessor :from_date,:to_date, :loan_product_id, :branch_id, :center_id, :staff_member_id

  def initialize(params, dates, user)

    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
   # @date   =  dates[:date]||Date.today
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
   # @loan_history = LoanHistory.all.map{|lh| [lh.loan_id,lh]}.to_hash
    @branch = Branch.all.map{ |b| [b.id,b.name]}.to_hash
    @center = Center.all.map{ |c| [c.id,c.name]}.to_hash
    @client_group = ClientGroup.all.map{ |cg| [cg.id,cg.name]}.to_hash
    @client = Client.all.map{|cl| [cl.id,cl.name]}.to_hash
    @loan = Loan.all.map{|l| [l.id,l.amount]}.to_hash
    @l = Loan.all
    @loan_product = LoanProduct.all.map{|lp| [lp.id,lp.name]}.to_hash
    lh = LoanHistory.all(:status => :repaid, :date.gte => @from_date, :date.lte => @to_date) + LoanHistory.all(:status => :written_off, :date.gte => @from_date, :date.lte => @to_date) + LoanHistory.all(:amount_in_default.lt => 0, :date.gte => @from_date, :date.lte => @to_date)
    
    lh.each{ |a|
      @data[a]||={}
      
      @data[a][0] = @branch[a.branch_id]
      @data[a][1] = @center[a.center_id]
      @data[a][2] = @client_group[a.client_group_id]
      @data[a][3] = @client[a.client_id]
      # @data[a][4] = @loan[a.loan_id].type
      @data[a][5] = @loan[a.loan_id]

      # 
      status =  a.status.to_s
      
      if status == 'repaid'
        @data[a][6] = 'Repayment'
      elsif status == 'written_off'
        @data[a][6] = 'Written off'
      elsif a.amount_in_default < 0
        @data[a][6] = 'Foreclosure'
      elsif @l[a.loan_id] != nil
        @data[a][6] = 'Insurance-claim-after Death'
      end
    }

    return @data
  end

  

  #<LoanHistory @loan_id=3079 @date=<Date: 09 April, 2013> @created_at=<Date: 2010-11-23T16:09:12+05:30> @run_number=0 @current=false @amount_in_default=10000.0 @days_overdue=882 @week_id=693 @scheduled_outstanding_total=0.0 @scheduled_outstanding_principal=0.0 @actual_outstanding_total=11500.0 @actual_outstanding_principal=10000.0 @principal_due=10000.0 @interest_due=1500.0 @principal_paid=0.0 @interest_paid=0.0 @status=:outstanding @center_id=163 @branch_id=3 @client_group_id=494 @client_id=3215>
end
