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
  property :scheduled_outstanding_total,     Integer, :nullable => false, :index => true
  property :scheduled_outstanding_principal, Integer, :nullable => false, :index => true
  property :actual_outstanding_total,        Integer, :nullable => false, :index => true
  property :actual_outstanding_principal,    Integer, :nullable => false, :index => true
  property :principal_due,                  Integer, :nullable => false, :index => true
  property :interest_due,                  Integer, :nullable => false, :index => true
  property :principal_paid,                  Integer, :nullable => false, :index => true
  property :interest_paid,                  Integer, :nullable => false, :index => true

  property :status,                          Enum.send('[]', *STATUSES)

  belongs_to :loan#, :index => true
  belongs_to :client, :index => true         # speed up reports
  belongs_to :client_group, :index => true, :nullable => true   # by avoiding 
  belongs_to :center, :index => true         # lots of joins!
  belongs_to :branch, :index => true         # muahahahahahaha!
  
  validates_present :loan,:scheduled_outstanding_principal,:scheduled_outstanding_total,:actual_outstanding_principal,:actual_outstanding_total


  # __DEPRECATED__ the prefered way to make history and future.
  # HISTORY IS NOW WRITTEN BY THE LOAN MODEL USING update_history_bulk_insert
  def self.add_group
    clients={}
    LoanHistory.all.each{|lh|
      next if lh.client_group_id or not lh.client_id
      
      clients[lh.client_id] = clients.key?(lh.client_id) ? clients[lh.client_id] : Client.get(lh.client_id)
      
      if clients[lh.client_id]
        lh.client_group_id = clients[lh.client_id].client_group_id
        if not lh.save
          lh.errors
        end
      end
    }
    puts "Done"
  end

  

  def self.write_for(loan, date)
    if result = LoanHistory::create(
      :loan_id =>                           loan.id,
      :date =>                              date,
      :status =>                            loan.get_status(date),
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

  # TODO should be private method?
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
        (select loan_id, max(date) as date from loan_history where date <= '#{date.to_s}' and loan_id in (#{loan_ids.join(', ')}) and status in (5,6) group by loan_id) as dt, 
        loan_history lh 
      where lh.loan_id = dt.loan_id and lh.date = dt.date) as dt1;})
  end

  def self.defaulted_loan_info (days = 7, date = Date.today, query ={})
    # this does not work as expected if the loan is repaid and goes back into default within the days we are looking at it.
    defaulted_loan_ids = repository.adapter.query(%Q{
      SELECT loan_id FROM
        (select loan_id, max(ddiff) as diff from (select date, loan_id, datediff(now(),date) as ddiff,actual_outstanding_principal - scheduled_outstanding_principal as diff from loan_history where actual_outstanding_principal != scheduled_outstanding_principal and date < now()) as dt group by loan_id having diff < #{days}) as dt1;})

  end
  
  def self.sum_outstanding_by_group(from_date, to_date)
    ids=repository.adapter.query("SELECT loan_id, max(date) date FROM loan_history 
                                  WHERE status in (5,6) AND date>='#{from_date}' AND date<='#{to_date}' GROUP BY loan_id"
                                 ).collect{|x| "(#{x.loan_id}, '#{x.date.to_s}')"}.join(",")
    repository.adapter.query(%Q{
      SELECT 
        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(actual_outstanding_principal)    AS actual_outstanding_principal,
        SUM(actual_outstanding_total)        AS actual_outstanding_total,
        client_group_id,
        center_id
      FROM loan_history
      WHERE (loan_id, date) in (#{ids}) 
      GROUP BY client_group_id;
    })
  end
end
