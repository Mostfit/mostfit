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

  # some properties for similarly named methods of a loan:
  property :scheduled_outstanding_principal, Integer, :nullable => false
  property :scheduled_outstanding_total,     Integer, :nullable => false
  property :actual_outstanding_principal,    Integer, :nullable => false
  property :actual_outstanding_total,        Integer, :nullable => false
  property :status,                          Enum[nil, :approved, :outstanding, :repaid, :written_off]

  belongs_to :loan

       validates_present :loan,:scheduled_outstanding_principal,:scheduled_outstanding_total,:actual_outstanding_principal,:actual_outstanding_total


  # the prefered way to make history and future.
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

#     WHERE loan_id in (#{loan_ids.join(', ')}) 
#       AND date IN
#                (SELECT MAX(date) FROM loan_history WHERE date <= '#{date.to_s}' AND loan_id IN (#{loan_ids.join(', ')}) 
#                 GROUP BY loan_id
#                 ORDER BY date DESC);})

#     SELECT 
#        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal,
#        SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
#        SUM(actual_outstanding_principal)    AS actual_outstanding_principal,
#        SUM(actual_outstanding_total)        AS actual_outstanding_total
#       FROM (( SELECT scheduled_outstanding_principal, scheduled_outstanding_total,
#                     actual_outstanding_principal, actual_outstanding_total, MAX(date) FROM loan_history
#               WHERE (loan_id IN (#{loan_ids.join(', ')})) AND (date <= '#{date.to_s}') GROUP BY loan_id) AS dt)} )
  end

end
