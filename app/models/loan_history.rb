class LoanHistory
  include DataMapper::Resource
  
#   property :id,                        Serial  # composite key transperantly enables history-rewriting
  property :loan_id,                   Integer, :key => true
  property :date,                      Date,    :key => true  # the day that this record applies to
  property :created_at,                DateTime  # automatic, nice for benchmarking runs
  property :run_number,                Integer, :nullable => false, :default => 0
  property :current,                   Boolean  # tracks the row refering to the loans current status. we can query for these
                                                # during reporting. I put it here to save an extra write to the db during 
                                                # update_history_now

  property :amount_in_default,          Integer # less normalisation = faster queries
  property :days_overdue,               Integer
  property :week_id,                    Integer # good for aggregating.

  # some properties for similarly named methods of a loan:
  property :scheduled_outstanding_principal, Integer, :nullable => false, :index => true
  property :scheduled_outstanding_total,     Integer, :nullable => false, :index => true
  property :actual_outstanding_principal,    Integer, :nullable => false, :index => true
  property :actual_outstanding_total,        Integer, :nullable => false, :index => true
  property :status,                          Enum[nil, :approved, :outstanding, :repaid, :written_off]

  belongs_to :loan, :index => true
  belongs_to :client, :index => true         # speed up reports
  belongs_to :center, :index => true         # by avoiding lots of joins!
  belongs_to :branch, :index => true         # muahahahahahaha!
  
  validates_present :loan,:scheduled_outstanding_principal,:scheduled_outstanding_total,:actual_outstanding_principal,:actual_outstanding_total


  # __DEPRECATED__ the prefered way to make history and future.
  # HISTORY IS NOW WRITTEN BY THE LOAN MODEL USING update_history_bulk_insert
  def self.write_for(loan, date)
    if result = LoanHistory::create(
      :loan_id =>                           loan.id,
      :date =>                              date,
      :status =>                            loan.status(date),
      :scheduled_outstanding_principal =>   loan.scheduled_outstanding_principal_on(date),
      :scheduled_outstanding_total =>       loan.scheduled_outstanding_total_on(date),
      :actual_outstanding_principal =>      loan.actual_outstanding_principal_on(date),
      :actual_outstanding_total =>          loan.actual_outstanding_total_on(date) )
      return result
    else
      Merb.logger.error! "Could not create a LoanHistory record, validations maybe?"
      Merb.logger.error! "errors object: #{result.errors.inspect}"
      return result
    end
  end

  def self.make_insert_for(loan, date)
    history = history_for(date)
    %Q{(#{history.id}, '#{date}', #{status}, #{history.scheduled_outstanding_principal_on(date)}, #{history.scheduled_outstanding_total_on(date)}, #{history.actual_outstanding_principal_on(date)},#{history.actual_outstanding_total_on(date)})}
  end

  def self.sum_outstanding_for(date, loan_ids)
    repository.adapter.query(%Q{
      SELECT
        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(actual_outstanding_principal)    AS actual_outstanding_principal,
        SUM(actual_outstanding_total)        AS actual_outstanding_total
      FROM
      (select scheduled_outstanding_principal,scheduled_outstanding_total, actual_outstanding_principal, actual_outstanding_total from
        (select loan_id, max(date) as date from loan_history where date <= '#{date.to_s}' and loan_id in (#{loan_ids.join(', ')}) group by loan_id) as dt, 
        loan_history lh 
      where lh.loan_id = dt.loan_id and lh.date = dt.date) as dt1;})
  end

  def self.defaulted_loan_info (days = 7, date = Date.today, query ={})
    # this does not work as expected if the loan is repaid and goes back into default within the days we are looking at it.
    defaulted_loan_ids = repository.adapter.query(%Q{
      SELECT loan_id FROM
        (select loan_id, max(ddiff) as diff from (select date, loan_id, datediff(now(),date) as ddiff,actual_outstanding_principal - scheduled_outstanding_principal as diff from loan_history where actual_outstanding_principal != scheduled_outstanding_principal and date < now()) as dt group by loan_id having diff < #{days}) as dt1;})

  end

end
