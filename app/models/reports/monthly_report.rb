class MonthlyReport < Report
  def initialize(month, year)
    self.start_date = Date.new(year, month, 1)
    self.end_date   = self.start_date + (Date.new(start_date.year,12,31).to_date<<(12-start_date.month)).day
    @name = "Monthly report for #{start_date.strftime("%B")}"
  end

  def name
    "Month of #{start_date.strftime("%B")}"
  end

  def to_str
    "#{start_date} - #{end_date}"
  end

  def calc
    @report = []
    t0 = Time.now
    t = Time.now
    puts "generating..."
    @report[0] = {'Number of Members' => Branch.client_count(end_date)}
    @report[1] = {'Number of Borrowers' => Branch.active_client_count(end_date)}
    (1..4).each do |i|
      @report[1+i] = { "Loan Cycle #{i}" => Branch.client_count_by_loan_cycle(i)}
    end
    Merb.logger.info "#{Time.now - t0}:#{Time.now - t}:did loan cycles. starting more than one loan"
    t = Time.now
    @report[6] = {"Active clients"  => Branch.active_client_count(end_date)}
#    Merb.logger.info "#{Time.now - t0}:#{Time.now - t}:did more than one loan. starting dormant"
    t = Time.now
    @report[7] = {"Dormant clients" => Branch.dormant_client_count(end_date)}
    Merb.logger.info "#{Time.now - t0}:#{Time.now - t}:did  dormant. starting last week dropouts"
    t = Time.now
    @report[8] = {"last_week_drop_outs" => Branch.clients_deleted_between_such_and_such_date_count(start_date, end_date)}
    Merb.logger.info "#{Time.now - t0}:#{Time.now - t}:did last week dropouts. starting last weeks additions"
    t = Time.now
    @report[9] = {"new_clients_last_week" => Branch.clients_added_between_such_and_such_date_count(start_date, end_date)}
    Merb.logger.info "#{Time.now - t0}:#{Time.now - t}:did last weeks additions. starting laons repaid (count)"
    t = Time.now
    @report[10] = { "Loans repaid in last week (count)" => Branch.loans_repaid_between_such_and_such_date(start_date, end_date, "count")}
    Merb.logger.info "#{Time.now - t0}:#{Time.now - t}:did last weeks additions. starting laons repaid (sum)"
    t = Time.now
    @report[11] = {"Loans repaid in last week (amount)" => Branch.loans_repaid_between_such_and_such_date(start_date, end_date, "sum")}
    Merb.logger.info "#{Time.now - t0}:#{Time.now - t}:did loans repaid (sum). starting principal_received last week"
    t = Time.now
    @report[12] = {"principal received last week" => Branch.principal_received_between_such_and_such_date(start_date, end_date) }
    Merb.logger.info "#{Time.now - t0}:#{Time.now - t}:did prin received. starting interest received last week"
    t = Time.now
      @report[13] = {"interest received last week" => Branch.interest_received_between_such_and_such_date(start_date, end_date)}
    Merb.logger.info "#{Time.now - t0}:#{Time.now - t}:did int received last week. starting os bals"
    t = Time.now
    @report[14] = {"total amount outstanding" => Branch.principal_outstanding(end_date)}
    @orig_bals = Branch.all.map {|b| Loan.all('client.center.branch_id' => b.id).sum(:amount)}
    @report[15] = {"average os bal per loanee" => Branch.avg_outstanding_balance}
    @report[16] = {"number of staff members" => Branch.center_managers(end_date)}
    @report[17] = {"number of center managers" => Branch.center_managers(end_date)}
    @report[18] = {"average clients / staff" => Branch.avg_client_count_per_center_managers([[end_date], [end_date]])}
    @report[19] = {"average clients / staff" => Branch.avg_client_count_per_center_managers([[end_date], [end_date]])}
    @report[20] = {"average balance / CM" => Branch.avg_current_principal_outstanding_per_center_managers([[end_date], [end_date]])}
    @report[21] = {"average borrowers / CM" => Branch.avg_active_client_count_per_center_managers([[end_date], [end_date]])}
    @report[22] = {"loans disbursed this week" => Branch.loans_disbursed_between_such_and_such_date(start_date, end_date, "count")}
    @report[23] = {"loans disbursed this week (amount)" => Branch.loans_disbursed_between_such_and_such_date(start_date, end_date, "sum")}
    @principal_due = Branch.principal_due_between_such_and_such_date(start_date, end_date)
    @interest_due = Branch.interest_due_between_such_and_such_date(start_date,end_date)
    @report[23] = {"principal due this week" => @principal_due}
    @report[24] = {"interest due this week" => @interest_due}
    @report[25] = {"principal received" => Branch.principal_received_between_such_and_such_date(start_date, end_date)}
    @report[25] = {"interest received" => Branch.interest_received_between_such_and_such_date(start_date, end_date)}
    @report[26] = {"7 days late amount" => Branch.overdue_by(0,7)}
    @report[27] = {"14 days late amount" => Branch.overdue_by(8,14)}
    @report[28] = {"21 days late amount" => Branch.overdue_by(9,21)}
    @report[29] = {"28 days late amount" => Branch.overdue_by(22,28)}
    self.raw = @report
    self.report = Marshal.dump(@report)
    self.generation_time = Time.now - t0
    self.save
  end
end
