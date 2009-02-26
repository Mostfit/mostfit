class LoanHistory
  include DataMapper::Resource
  
#   property :id,                        Serial  # composite key transperantly enables history-rewriting
  property :loan_id,                   Integer, :key => true
  property :date,                      Date,    :key => true  # the day that this record applies to
  property :created_at,                DateTime  # automatic, nice for benchmarking runs
  property :run_number,                Integer, :nullable => false, :default => 0

  # some properties for similarly named methods of a loan:
  property :scheduled_outstanding_principal, Integer, :nullable => false
  property :scheduled_outstanding_total,     Integer, :nullable => false
  property :actual_outstanding_principal,    Integer, :nullable => false
  property :actual_outstanding_total,        Integer, :nullable => false
  property :status,                          Enum[nil, :approved, :outstanding, :repaid, :written_off]

  belongs_to :loan

#  validates_present :loan  # the rest does with autovalidations


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

  # this method gets call for history aggregation.
  # i.e. making a graph, for every 'measurment' in the graph (a bunch of date on the x axis)
  # this method is called once.
  def self.sum_outstanding_for(date, loan_ids)
    repository.adapter.query("
      SELECT  
        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(actual_outstanding_principal)    AS actual_outstanding_principal,
        SUM(actual_outstanding_total)        AS actual_outstanding_total
       FROM( SELECT scheduled_outstanding_principal, scheduled_outstanding_total,
                     actual_outstanding_principal, actual_outstanding_total, MAX(date) FROM loan_history
               WHERE (loan_id IN (#{loan_ids.join(', ')})) AND (date <= #{date.to_s.inspect})
            GROUP BY loan_id ) AS derived_table" )[0]  # in case of nil errors add: .map { |x| x.nil? ? 0 : x }  # nil -> 0
  end

end
