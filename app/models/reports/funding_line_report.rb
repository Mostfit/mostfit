class FundingLineReport < Report
  
  def initialize(start_date)
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
    puts "generating..."
    @report[0] = {'Number of Borrowers' => FundingLine.active_client_count(start_date, end_date)}
    (1..4).each do |i|
      @report[i] =  { "Loan borrower in Cycle #{i}" => FundingLine.client_count_by_loan_cycle(i)}
    end
    @report << {'With more than one Loan' => FundingLine.more_than_one_loan(start_date, end_date)}
    @report << {"Total number outstanding" => FundingLine.loans_outstanding(start_date, end_date)}
    @report << {"Total amount outstanding" => FundingLine.amount_outstanding(start_date, end_date)}
    @report << {"Average amount outstanding" => FundingLine.average_amount_outstanding(start_date, end_date)}
    @report << {"Total number of loan officers" => FundingLine.total_number_of_loan_officers(start_date, end_date)}
    @report << {"Total number of loan officers" => FundingLine.total_number_of_loan_officers(start_date, end_date)}
    @report << {"Borrowers per loan officer" => FundingLine.borrowers_per_loan_officers(start_date, end_date)}
    @report << {"Loan amount per loan officer" => FundingLine.loan_amount_per_loan_officers(start_date, end_date)}

    @report << {"Number of loans disbursed" => FundingLine.number_of_loans_disbursed(start_date, end_date)}
    @report << {"Amount of loans disbursed" => FundingLine.amount_of_loans_disbursed(start_date, end_date)}
    @report << {"Principal due for members" => FundingLine.principal_due(start_date, end_date)}
    @report << {"Repayments excluding prepayments" => FundingLine.repayments_excluding_prepayments(start_date, end_date)}
    @report << {"Portfolio at risk" => FundingLine.portfolio_at_risk(start_date, end_date)}
    @report << {"Repayment rate" => FundingLine.repayment_rate(start_date, end_date)}
    @report << {"Outstanding borrowings" => FundingLine.outstanding_borrowings(start_date, end_date)}
    @report << {"Amounts per agency" => FundingLine.amounts_per_agency(start_date, end_date)}

    @report << {"Number of Loans disbursed" => Organization.disbursed(end_date, "count")}
    @report << {"Amount of Loans disbursed" => Organization.disbursed(end_date, "sum")}

    self.raw = @report
    self.report = Marshal.dump(@report)
    self.generation_time = Time.now - t0
    self.save
  end  

end
