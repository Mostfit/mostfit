class WeeklyReport < Report  
  def initialize(start_date)
    self.start_date = (start_date.is_a? Date) ? start_date : Date.parse(start_date)
    self.end_date   = self.start_date + 6
    @name = "weekly report"
  end

  def name
    "Week starting #{self.start_date} upto #{self.end_date}"
  end

  def to_str
    "#{start_date} - #{end_date}"
  end

  def calc
    t0 = Time.now
    @report = []
    @report << {"Number of Center Managers" => Branch.center_managers_count(end_date)}
    @report << {'Total number of Centers' => Branch.center_count(Date.min_date, end_date)}
    @report << {"Total number of Groups"  => Branch.client_groups_count(end_date)}
    @report << {'Total number of Clients' => Branch.client_count(end_date)}
    @report << {"Total number of Borrower Clients" => Branch.borrower_clients_count(end_date)}
    @report << {"Active Clients"  => Branch.active_client_count(end_date)}
    @report << {"Dormant Clients" => Branch.dormant_client_count(end_date)}
    @report << {'Total number of Loans' => Branch.loan_count(end_date)}
    (1..4).each do |i|
      @report << {"Loan Cycle #{i}" => Branch.client_count_by_loan_cycle(i, end_date)}
    end
    @report << {'Total Loan Disbursed so far' => Branch.loan_amount(end_date)}
    @report << {"Principal Amount Received" => Branch.principal_amount(end_date) }
    @report << {"Principal Amount Outstanding" => Branch.principal_outstanding(end_date)}
    @report << {"Total Amount Outstanding" => Branch.total_outstanding(end_date)}
    @report << {"Total Balance Overdue" => Branch.principal_overdue_by(end_date)}

    @report << {"Average Loan Size per Client" => Branch.avg_loan_size_per_client(end_date)}
    @report << {"Average Loan Size per Center Manager" => Branch.avg_loan_size_per_cm(end_date)}
    @report << {"Average Outstanding Balance per Client" => Branch.avg_outstanding_balance_per_client(end_date)}
    @report << {"Average Outstanding Balance per Center Manager" => Branch.avg_outstanding_balance_per_cm(end_date)}

    @report << {"Income" => Branch.income(end_date)}
    @report << {"Interest" => Branch.interest_amount(end_date)}
    @report << {"Fees" => Branch.fee_received(end_date)} 
    @report << {"Loan Fee" => Branch.loan_fee(end_date)}
    @report << {"Card Fee" => Branch.card_fee(end_date)}
#    @report << {"Total Income - New" }
#    @report << {"Total Income - Old" }
    @report << {"New Clients Last Week" => Branch.clients_added_between(start_date, end_date)}
    @report << {'New Centers Last Week' => Branch.center_count(start_date, end_date)}
    @report << {"Loans Applied in Last Week (count)"  => Branch.loans_applied_between(start_date, end_date, "count")}
    @report << {"Loans Applied in Last Week (amount)" => Branch.loans_applied_between(start_date, end_date, "sum")}
    @report << {"Loans Sanctioned in Last Week (count)"  => Branch.loans_approved_between(start_date, end_date, "count")}
    @report << {"Loans Sanctioned in Last Week (amount)" => Branch.loans_approved_between(start_date, end_date, "sum")}
    @report << {"Loans Disbursed Last Week (count)"  => Branch.loans_disbursed_between(start_date, end_date, "count")}
    @report << {"Loans Disbursed Last Week (amount)" => Branch.loans_disbursed_between(start_date, end_date, "sum")}
    @report << {"Principal Received Last Week" => Branch.principal_received_between(start_date, end_date) }
    @report << {"Interest Received Last Week" => Branch.interest_received_between(start_date, end_date)}
    @report << {"Fees Received Last Week" => Branch.fee_received_between(start_date, end_date)}
    @report << {"Advance Payment Total Last Week" => Branch.overpaid_total_between(start_date, end_date)}
    @report << {"Balance Overdue Last Week" => Branch.principal_overdue_last_week(7, end_date)}

    WeeklyReport.all(:start_date => self.start_date, :end_date => self.end_date).destroy!
    self.raw = @report
    self.report = Marshal.dump(@report)
    self.generation_time = Time.now - t0
    self.save
  end
end
