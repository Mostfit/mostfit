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
    repository.adapter.query(%Q{
      SELECT "loan_id", "date", "created_at", "run_number", "scheduled_outstanding_principal", "scheduled_outstanding_total", "actual_outstanding_principal", "actual_outstanding_total", "status"
      FROM "loan_history"
      WHERE "loan_id" = #{loan_id}
        AND "date" IN (#{(dates.map { |x| x.to_s.inspect }).join(', ')})
      ORDER BY "date"})
  end

  def self.raw_structs_for_loans(loan_ids, dates)
    repository.adapter.query(%Q{
      SELECT
        "date",
        SUM ("scheduled_outstanding_principal") AS "scheduled_outstanding_principal",
        SUM ("scheduled_outstanding_total")     AS "scheduled_outstanding_total",
        SUM ("actual_outstanding_principal")    AS "actual_outstanding_principal",
        SUM ("actual_outstanding_total")        AS "actual_outstanding_total"
       FROM "loan_history"
      WHERE ("loan_id" IN (#{(loan_ids.map { |x| x.to_s.inspect }).join(', ')}))
        AND ("date" IN (#{(dates.map { |x| x.to_s.inspect }).join(', ')}))
      GROUP BY "date"
      ORDER BY "date"})
  end

  # returns an array with max_outstanding_principal[0] and sum_outstanding_total[1]
  # for all the loans that the id was supplied.
  # typically used by the graphing dept. for knowing the plotting range on the y axis.
  def self.max_outstanding(loan_ids, start_date, end_date)
    repository.adapter.query(%Q{
      SELECT
        MAX ("sum_outstanding_principal") AS "max_outstanding_principal",
        MAX ("sum_outstanding_total")     AS "max_outstanding_total"
       FROM (
          SELECT
            SUM ("scheduled_outstanding_principal") AS "sum_outstanding_principal",
            SUM ("scheduled_outstanding_total")     AS "sum_outstanding_total"
           FROM "loan_history"
          WHERE ("loan_id" IN (#{(loan_ids.map { |x| x.to_s.inspect }).join(', ')}))
            AND ("date" >= #{start_date.to_s.inspect})
            AND ("date" <= #{end_date.to_s.inspect})
          GROUP BY "date" )})[0].to_a  # in case of nil errors add: .map { |x| x.nil? ? 0 : x }  # nil -> 0
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
    history_record = LoanHistory.first(keys.merge(:fields => [:loan_id, :date]))  # dont pull to much
    if history_record.blank?
      LoanHistory::create(keys.merge(other_attributes))  # pass both the key and the other attributes
    else
      result = history_record.update_attributes(other_attributes)  # dont pass the keys
      unless result
        Merb.logger.error! "Validation errors saving a LoanHistory record:"
        Merb.logger.error! result.errors.inspect
      end
#       begin
#         history_record.update_attributes(properties)
#       rescue Sqlite3Error  # trying a few times incase the sqlite3 db is locked, mysql will not have this problem...
#         sleep(1)
#         history_record.update_attributes(properties)
#       rescue Sqlite3Error
#         sleep(1)
#         history_record.update_attributes(properties)
#       ensure
      return result
#       end
    end
  end

end
