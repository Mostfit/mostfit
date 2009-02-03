class LoanHistory
  include DataMapper::Resource
  
#   property :id,                        Serial  # composite key transperantly enables history-rewriting
  property :loan_id,                   Integer, :key => true
  property :for_date,                  Date,    :key => true  # the day that this record applies to
  property :created_at,                DateTime  # automatic, nice for benchmarking runs
  property :run_number,                Integer, :nullable => false

#### properties for methods (derived/calculates values) of a loan
# (most of them end on: _on(date))
# propably we dont need so much, but alas..
#   property :total_to_be_received,      Integer, :nullable => false  # some commented out as we dont need 'm (yet)

  property :total_scheduled_principal, Integer, :nullable => false
#   property :total_scheduled_interest,  Integer, :nullable => false
  property :total_scheduled,           Integer, :nullable => false

  property :total_received_principal,  Integer, :nullable => false
#   property :total_received_interest,   Integer, :nullable => false
  property :total_received,            Integer, :nullable => false

#   property :principle_difference,      Integer, :nullable => false
#   property :interest_difference,       Integer, :nullable => false
#   property :total_difference,          Integer, :nullable => false

  property :status,                    Enum[nil, :approved, :disbursed, :repaid, :written_off]
#### end

  belongs_to :loan



  def self.run(date = Date.today)
    run_number = (LoanHistory.max(:run_number) or 0) + 1
    loans = Loan.all(:order => [:created_at])
    t0 = Time.now
    Merb.logger.info! "Start LoanHistory run ##{run_number}, for #{loans.size} loans, at #{t0}"
    loans.each do |loan|
      LoanHistory.write_for(loan, run_number, date)
      puts  # make reading the console output a little easier
    end
    t1 = Time.now
    secs = (t1 - t0).round
    Merb.logger.info! "Finished LoanHistory run ##{run_number}, in #{secs} secs (#{format("%.3f", secs.to_f/loans.size)} secs/loan), at #{t1}"
  end

  def self.write_for(loan, run_number, date = Date.today)
    LoanHistory::create(
      :loan_id =>                   loan.id,
      :for_date =>                  date,
      :run_number =>                run_number,
#       :total_to_be_received =>      loan.total_to_be_received,  # some commented out as we dont need 'm (yet)
      :status =>                    loan.status(date),
      :total_scheduled_principal => loan.total_scheduled_principal_on(date),
#       :total_scheduled_interest =>  loan.total_scheduled_interest_on(date),
      :total_scheduled =>           loan.total_scheduled_on(date),
      :total_received_principal =>  loan.total_received_principal_on(date),
#       :total_received_interest =>   loan.total_received_interest_on(date),
      :total_received =>            loan.total_received_on(date)
#,
#       :principle_difference =>      loan.principle_difference_on(date),
#       :interest_difference =>       loan.interest_difference_on(date),
#       :total_difference =>          loan.total_difference_on(date)
      )
  end

  def get_overview(interval = :weekly , to = Date.today)
  end
end
