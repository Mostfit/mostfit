class LoanHistory
  include DataMapper::Resource
  
#   property :id,                        Serial  # composite key transperantly enables history-rewriting
  property :loan_id,                   Integer, :key => true
  property :date,                      Date,    :key => true  # the day that this record applies to
  property :created_at,                DateTime  # automatic, nice for benchmarking runs
  property :run_number,                Integer, :nullable => false

  # some properties for similarly named methods of a loan:
  property :scheduled_outstanding_principal, Integer, :nullable => false
  property :scheduled_outstanding_total,     Integer, :nullable => false
  property :actual_outstanding_principal,    Integer, :nullable => false
  property :actual_outstanding_total,        Integer, :nullable => false
  property :status,                          Enum[nil, :approved, :disbursed, :repaid, :written_off]

  belongs_to :loan
  

  def self.raw_structs_for_loan(loan_id, dates)
    raw = repository.adapter.query(%Q{
      SELECT "loan_id", "date", "created_at", "run_number", "scheduled_outstanding_principal", "scheduled_outstanding_total", "actual_outstanding_principal", "actual_outstanding_total", "status"
      FROM "loan_history"
      WHERE "loan_id" = #{loan_id}
        AND "date" IN (#{(dates.map { |x| x.to_s.inspect }).join(', ')})
      ORDER BY "date"})
  end

  def self.raw_structs_for_loans(loan_ids, dates)
    raw = repository.adapter.query(%Q{
      SELECT
        "date",
        SUM("scheduled_outstanding_principal") AS "scheduled_outstanding_principal",
        SUM("scheduled_outstanding_total")     AS "scheduled_outstanding_total",
        SUM("actual_outstanding_principal")    AS "actual_outstanding_principal",
        SUM("actual_outstanding_total")        AS "actual_outstanding_total"
       FROM "loan_history"
      WHERE "loan_id" IN (#{(loan_ids.map { |x| x.to_s.inspect }).join(', ')})
        AND "date" IN (#{(dates.map { |x| x.to_s.inspect }).join(', ')})
      GROUP BY "date"
      ORDER BY "date"})
  end

  # the prefered way to make history and future.
  def self.write_for(loan, run_number, date = Date.today)
    keys = {
      :loan_id =>                           loan.id,
      :date =>                              date }
    other_attributes = {
      :run_number =>                        run_number,
      :status =>                            loan.status(date),
      :scheduled_outstanding_principal =>   loan.scheduled_outstanding_principal_on(date),
      :scheduled_outstanding_total =>       loan.scheduled_outstanding_total_on(date),
      :actual_outstanding_principal =>      loan.actual_outstanding_principal_on(date),
      :actual_outstanding_total =>          loan.actual_outstanding_total_on(date) }
    history_record = LoanHistory.first(keys.merge(:fields => [:loan_id]))  # dont pull to much
    unless history_record.blank?
      history_record.update_attributes(other_attributes)  # dont pass the keys
      "DONE!"
#       begin  # trying a few times incase the sqlite3 db is locked, mysql will not have this problem...
#         history_record.update_attributes(properties)
#       rescue Sqlite3Error
#         sleep(1)
#         history_record.update_attributes(properties)
#       rescue Sqlite3Error
#         sleep(1)
#         history_record.update_attributes(properties)
#       end
    else
      LoanHistory::create(keys.merge(other_attributes))
    end
  end

end
