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
    @report << {'Total number of centers' => Branch.center_count(Date.min_date, end_date)}
    @report << {'Total number of clients' => Branch.client_count(end_date)}
    @report << {'Total number of loans' => Branch.loan_count(end_date)}
    @report << {'Total amount disbursed so far' => Branch.loan_amount(end_date)}
    @report << {"Active clients"  => Branch.active_client_count(end_date)}
    (1..4).each do |i|
      @report << {"Loan Cycle #{i}" => Branch.client_count_by_loan_cycle(i, end_date)}
    end

    @report << {"Dormant clients" => Branch.dormant_client_count(end_date)}
    @report << {"Last week drop outs" => Branch.clients_deleted_between(start_date, end_date)}
    @report << {"New clients last week" => Branch.clients_added_between(start_date, end_date)}
    @report << {'New centers last week' => Branch.center_count(start_date, end_date)}

    @report << {"Loans disbursed last week (count)"  => Branch.loans_disbursed_between(start_date, end_date, "count")}
    @report << {"Loans disbursed last week (amount)" => Branch.loans_disbursed_between(start_date, end_date, "sum")}

    @report << {"Loans applied in last week (count)"  => Branch.loans_applied_between(start_date, end_date, "count")}
    @report << {"Loans applied in last week (amount)" => Branch.loans_applied_between(start_date, end_date, "sum")}

    @report << {"Loans approved last week (count)"  => Branch.loans_approved_between(start_date, end_date, "count")}
    @report << {"Loans approved last week (amount)" => Branch.loans_approved_between(start_date, end_date, "sum")}

    @report << {"Loans repaid last week (count)" => Branch.loans_repaid_between(start_date, end_date, "count")}
    @report << {"Loans repaid last week (amount)" => Branch.loans_repaid_between(start_date, end_date, "sum")}

    @report << {"Principal received last week" => Branch.principal_received_between(start_date, end_date) }
    @report << {"Interest received last week" => Branch.interest_received_between(start_date, end_date)}

    @report << {"Principal amount outstanding" => Branch.principal_outstanding(end_date)}
    @report << {"Total amount outstanding" => Branch.total_outstanding(end_date)}

    @report << {"Overpaid principal this week" => Branch.overpaid_principal_between(start_date, end_date)}
    @report << {"Overpaid total this week" => Branch.overpaid_total_between(start_date, end_date)}

    [7, 14, 21, 28].each{|d|      
      @report << {"Max. #{d} days late amount"  => Branch.principal_overdue_by(d, end_date)}
    }

    @report << {"Average os bal per loanee" => Branch.avg_outstanding_balance(end_date)}
    @report << {"Number of staff members" => Branch.center_managers(end_date)}
    @report << {"Number of center managers" => Branch.center_managers(end_date)}
    @report << {"Average clients / staff" => Branch.avg_client_count_per_center_managers([[end_date], [end_date]])}
    @report << {"Average balance / CM" => Branch.avg_principal_outstanding_per_center_managers([[end_date],[end_date]])}
    @report << {"Average borrowers / CM" => Branch.avg_active_client_count_per_center_managers([[end_date], [end_date]])}
    WeeklyReport.all(:start_date => self.start_date, :end_date => self.end_date).destroy!
    self.raw = @report
    self.report = Marshal.dump(@report)
    self.generation_time = Time.now - t0
    self.save
  end
end
