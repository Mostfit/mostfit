class WeeklyReport

  attr_accessor :start_date, :end_date, :report, :name
  
  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
    @name = "weekly report"
  end

  def calc
    @report = []
    puts "generating..."
    @report[0] = {'Number of Members' => Branch.all.map{ |b| Client.all('center.branch_id' => b.id).count}}
    @report[1] = {'Number of Borrowers' => Branch.all.map{ |b| Client.active('center.branch_id' => b.id).count}}
    (1..4).each do |i|
      @report[1+i] = { "Loan Cycle #{i}" => Branch.all.map{ |b| Client.find_by_loan_cycle(i,'center.branch_id' => b.id).count }}
    end
    @report[6] = {"More than one loan"  => Branch.all.map{ |b| Client.active({'center.branch_id' => b.id}, ">", 1).count }}
    @report[7] = {"Dormant clients" => Branch.all.map{ |b| Client.dormant('center.branch_id' => b.id).count }}
    @report[8] = {"last_week_drop_outs" => Branch.all.map{ |b| Client.all('center.branch_id' => b.id, :deleted_at.gte => @start_date, :deleted_at.lte => @end_date).count }}
    @report[9] = {"new_clients_last_week" => Branch.all.map{ |b| Client.all('center.branch_id' => b.id, :date_joined.gte => @start_date, :deleted_at.lte => @end_date).count }}
    @branch_ids = []
    @repaid_ids = []
    @staff_members = []
    @start_sum, @end_sum = [], []
    @defaulted_loan_ids = {}
    Branch.all.each do |b|
      @branch_ids[b.id] = LoanHistory.all(:current => true, :date.gt => @start_date, :date.lt => @end_date,  :fields => ['loan_id'], :branch_id => b.id).map{|h| h.loan_id}
      @repaid_ids[b.id] = LoanHistory.all(:current => true, :status => :repaid, :date.gt => @start_date, :date.lt => @end_date,  :fields => ['loan_id'], :branch_id => b.id).map{|h| h.loan_id}
      @staff_members[b.id] = b.centers.manager.uniq.size + 1
      @start_sum[b.id] = @branch_ids[b.id].empty? ? 0 : LoanHistory.sum_outstanding_for(@start_date, @branch_ids[b.id]) 
      @end_sum[b.id] = @branch_ids[b.id].empty? ? 0 : LoanHistory.sum_outstanding_for(@end_date, @branch_ids[b.id])
    end
    @report[10] = { "Loans repaid in last week (count)" => Branch.all.map{ |b| Loan.all(:id.in => @repaid_ids[b.id]).count }}
    @report[11] = {"Loans repaid in last week (amount)" => Branch.all.map{ |b| Loan.all(:id.in => @repaid_ids[b.id]).sum(:amount) }}
    @payments = Branch.all.map{ |b| Payment.all(:received_on.gt => @start_date, :received_on.lt => @end_date, :loan_id.in => @branch_ids[b.id])}
    @prin_received = @payments.map {|p| p.sum(:principal)}
    @int_received = @payments.map {|p| p.sum(:interest)}
    @report[12] = {"principal received last week" => @prin_received }
    @report[13] = {"interest received last week" => @int_received }
    @os_bals = Branch.all.map{ |b| LoanHistory.all(:branch_id => b.id, :current => true).sum(:actual_outstanding_principal)}
    @report[14] = {"total amount outstanding" => @os_bals}
    @orig_bals = Branch.all.map {|b| Loan.all('client.center.branch_id' => b.id).sum(:amount)}
    @report[15] = {"total original amount" => @orig_bals}
    @avg_balances = []
    @avg_balance_per_cm = []
    @avg_borrowers_per_cm = []
    @report[1][@report[1].keys[0]].each_with_index do |v,i|
      @avg_balances[i] =  @os_bals[i].to_f / v
      @avg_balance_per_cm[i] = @os_bals[i].to_f / (@staff_members[i+1]-1)
      @avg_borrowers_per_cm[i] = v / (@staff_members[i+1]-1)
    end
    @report[15] = {"average os bal per loanee" => @avg_balances}
    @report[16] = {"number of staff members" => @staff_members[1..-1]}
    @report[17] = {"number of center managers" => @staff_members[1..-1].map{|x| x-1}}
    @avg_staff_member_per_client = []
    @avg_member_per_cm = []
    @report[0][@report[0].keys[0]].each_with_index do |v,i|
      @avg_staff_member_per_client[i] = v.to_f / @staff_members[i+1]
      @avg_member_per_cm[i] = v.to_f / (@staff_members[i+1]-1)
    end
    @report[18] = {"average clients / staff" => @avg_staff_member_per_client}
    @report[19] = {"average clients / CM" => @avg_member_per_cm}
    @report[20] = {"average balance / CM" => @avg_balance_per_cm}
    @report[21] = {"average borrowers / CM" => @avg_borrowers_per_cm}
    @report[22] = {"loans disbursed this week" => Branch.all.map { |b| Loan.all(:id.in => @branch_ids[b.id], :disbursal_date.gt => @start_date, :disbursal_date.lt => @end_date).count}}
    @report[23] = {"loans disbursed this week (amount)" => Branch.all.map { |b| Loan.all(:id.in => @branch_ids[b.id], :disbursal_date.gt => @start_date, :disbursal_date.lt => @end_date).sum(:amount)}}
    @principal_due = Branch.all.map { |b| @end_sum[b.id][0][:scheduled_outstanding_principal].to_i - @start_sum[b.id][0][:actual_outstanding_principal].to_i}
    @interest_due = Branch.all.map { |b| (@end_sum[b.id][0][:scheduled_outstanding_total].to_i - @end_sum[b.id][0][:scheduled_outstanding_principal].to_i) - (@start_sum[b.id][0][:actual_outstanding_total].to_i - @start_sum[b.id][0][:actual_outstanding_principal].to_i)}
    @report[23] = {"principal due this week" => @principal_due}
    @report[24] = {"interest due this week" => @interest_due}
    @report[25] = {"principal received" => @prin_received}
    @report[25] = {"interest received" => @int_received}
    @report[26] = {"7 days late" => Branch.all.map {|b| LoanHistory.all(:current => true, :branch_id => b.id, :days_overdue.lte => 7).sum(:amount_in_default)}}
    @report[27] = {"14 days late" => Branch.all.map {|b| LoanHistory.all(:current => true, :branch_id => b.id, :days_overdue.gt => 7, :days_overdue.lte => 14).sum(:amount_in_default)}}
    @report[28] = {"21 days late" => Branch.all.map {|b| LoanHistory.all(:current => true, :branch_id => b.id, :days_overdue.gt => 14, :days_overdue.lte => 21).sum(:amount_in_default)}}
    @report[29] = {"28 days late" => Branch.all.map {|b| LoanHistory.all(:current => true, :branch_id => b.id, :days_overdue.gt => 21, :days_overdue.lte => 28).sum(:amount_in_default)}}
    return @report

  end
end
