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
    @report << {'Number of Members' => Branch.client_count(end_date)}
    @report << {'Number of Borrowers' => Branch.active_client_count(end_date)}
    (1..4).each do |i|
      @report << { "Loan Cycle #{i}" => Branch.client_count_by_loan_cycle(i)}
    end
    @report << {"Active clients"  => Branch.active_client_count(end_date)}
    @report << {"Dormant clients" => Branch.dormant_client_count(end_date)}
    @report << {"last_week_drop_outs" => Branch.clients_deleted_between_such_and_such_date_count(start_date, end_date)}
    @report << {"new_clients_last_week" => Branch.clients_added_between_such_and_such_date_count(start_date, end_date)}
    @report << { "Loans repaid in last week (count)" => Branch.loans_repaid_between_such_and_such_date(start_date, end_date, "count")}
    @report << {"Loans repaid in last week (amount)" => Branch.loans_repaid_between_such_and_such_date(start_date, end_date, "sum")}
    @report << {"principal received last week" => Branch.principal_received_between_such_and_such_date(start_date, end_date) }
    @report << {"interest received last week" => Branch.interest_received_between_such_and_such_date(start_date, end_date)}
    @report << {"total amount outstanding" => Branch.principal_outstanding(end_date)}
    @orig_bals = Branch.all.map {|b| Loan.all('client.center.branch_id' => b.id).sum(:amount)}
    @report << {"average os bal per loanee" => Branch.avg_outstanding_balance}
    @report << {"number of staff members" => Branch.center_managers(end_date)}
    @report << {"number of center managers" => Branch.center_managers(end_date)}
    @report << {"average clients / staff" => Branch.avg_client_count_per_center_managers([[end_date], [end_date]])}
    @report << {"average clients / staff" => Branch.avg_client_count_per_center_managers([[end_date], [end_date]])}
    @report << {"average balance / CM" => Branch.avg_principal_outstanding_per_center_managers([[end_date],[end_date]])}
    @report << {"average borrowers / CM" => Branch.avg_active_client_count_per_center_managers([[end_date], [end_date]])}
    @report << {"loans disbursed this week" => Branch.loans_disbursed_between_such_and_such_date(start_date, end_date, "count")}
    @report << {"loans disbursed this week (amount)" => Branch.loans_disbursed_between_such_and_such_date(start_date, end_date, "sum")}
    @principal_due = Branch.principal_due_between_such_and_such_date(start_date, end_date)
    @interest_due = Branch.interest_due_between_such_and_such_date(start_date,end_date)
    @report << {"principal due this week" => @principal_due}
    @report << {"interest due this week" => @interest_due}
    @report << {"principal received" => Branch.principal_received_between_such_and_such_date(start_date, end_date)}
    @report << {"interest received" => Branch.interest_received_between_such_and_such_date(start_date, end_date)}
    @report << {"7 days late amount" => Branch.overdue_by(0,7)}
    @report << {"14 days late amount" => Branch.overdue_by(8,14)}
    @report << {"21 days late amount" => Branch.overdue_by(9,21)}
    @report << {"28 days late amount" => Branch.overdue_by(22,28)}
    self.raw = @report
    self.report = Marshal.dump(@report)
    self.generation_time = Time.now - t0
    self.save
  end
end
