class LoanHistory
  include DataMapper::Resource
  
#   property :id,                        Serial  # composite key transperantly enables history-rewriting
  property :loan_id,                   Integer, :key => true
  property :date,                      Date,    :key => true  # the day that this record applies to
  property :created_at,                DateTime  # automatic, nice for benchmarking runs
  property :run_number,                Integer, :nullable => false, :default => 0
  property :current,                   Boolean  # tracks the row refering to the loans current status. we can query for these
                                                # during reporting. I put it here to save an extra write to the db during update_history_now
  property :amount_in_default,          Float # less normalisation = faster queries
  property :days_overdue,               Integer
  property :week_id,                    Integer # good for aggregating.

  # some properties for similarly named methods of a loan:
  property :scheduled_outstanding_total,     Float, :nullable => false, :index => true
  property :scheduled_outstanding_principal, Float, :nullable => false, :index => true
  property :actual_outstanding_total,        Float, :nullable => false, :index => true
  property :actual_outstanding_principal,    Float, :nullable => false, :index => true
  property :principal_due,                   Float, :nullable => false, :index => true
  property :interest_due,                    Float, :nullable => false, :index => true
  property :principal_paid,                  Float, :nullable => false, :index => true
  property :interest_paid,                   Float, :nullable => false, :index => true

  property :status,                          Enum.send('[]', *STATUSES)

  property :client_id,                   Integer, :index => true
  property :client_group_id,             Integer, :index => true
  property :center_id,                   Integer, :index => true
  property :branch_id,                   Integer, :index => true

  belongs_to :loan#, :index => true
  belongs_to :client         # speed up reports
  belongs_to :client_group, :nullable => true   # by avoiding 
  belongs_to :center         # lots of joins!
  belongs_to :branch         # muahahahahahaha!
  
  validates_present :loan,:scheduled_outstanding_principal,:scheduled_outstanding_total,:actual_outstanding_principal,:actual_outstanding_total

  @@selects = {Branch => "b.id", Center => "c.id", Client => "cl.id", Loan => "l.id", Area => "a.id", Region => "r.id", ClientGroup => "cg.id", Portfolio => "p.id"}
  @@tables = ["regions r", "areas a", "branches b", "centers c", "client_groups cg", "clients cl", "loans l"]
  @@models = [Region, Area, Branch, Center, ClientGroup, Client, Loan]
  @@optionals = [ClientGroup]

  
  # Provides outstanding amount of loans given as ids on a particular date
  def self.sum_outstanding_for_loans(date, loan_ids)
    loan_ids = loan_ids.length > 0 ? loan_ids.join(', ') : "NULL"
    repository.adapter.query(%Q{
      SELECT
        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(actual_outstanding_principal)    AS actual_outstanding_principal,
        SUM(actual_outstanding_total)        AS actual_outstanding_total
      FROM
      (select scheduled_outstanding_principal,scheduled_outstanding_total, actual_outstanding_principal, actual_outstanding_total from
        (select loan_id, max(date) as date from loan_history where date <= '#{date.strftime('%Y-%m-%d')}' and loan_id in (#{loan_ids}) and status in (5,6,7,8) group by loan_id) as dt, 
        loan_history lh
      where lh.loan_id = dt.loan_id and lh.date = dt.date) as dt1;})
  end

  # Provides loan ids which have defaulted for more than 'days'
  def self.defaulted_loan_info (days = 7, date = Date.today, query ={})
    # this does not work as expected if the loan is repaid and goes back into default within the days we are looking at it.
    defaulted_loan_ids = repository.adapter.query(%Q{
      SELECT loan_id FROM
        (SELECT loan_id, max(ddiff) as diff 
         FROM (SELECT date, loan_id, datediff(now(),date) as ddiff,actual_outstanding_principal - scheduled_outstanding_principal as diff 
               FROM loan_history 
               WHERE actual_outstanding_principal != scheduled_outstanding_principal and date < now()) as dt group by loan_id having diff < #{days}) as dt1;})
  end

  
  # Get loans defaulted grouped by given group_by
  # For instance we can group loans by [:branch, :center] or [:branch, :center, :client_group]
  # by saying LoanHistory.defaulted_loan_info_by([:branch, :center], Date.today)
  # on can also restrict the scope of the query by providing 'query'
  # for instance, query = {:branch_id => [3, 4]}
  def self.defaulted_loan_info_by(group_by, date = Date.today, query={}, selects="")
    # this does not work as expected if the loan is repaid and goes back into default within the days we are looking at it.
    group_by_query = get_group_by(group_by)
    selects        = get_selects(group_by, selects)
    subtable       = get_subtable(date, query)

    repository.adapter.query(%Q{
         SELECT SUM(lh.actual_outstanding_principal - lh.scheduled_outstanding_principal) as pdiff, 
                SUM(lh.actual_outstanding_total -     lh.scheduled_outstanding_total) as tdiff, 
                #{selects}
         FROM #{subtable} dt, loan_history lh, loans l
         WHERE lh.loan_id=dt.loan_id AND lh.date=dt.date AND lh.loan_id = l.id AND l.deleted_at is NULL AND l.rejected_on is NULL
               AND lh.actual_outstanding_principal > lh.scheduled_outstanding_principal
               AND lh.actual_outstanding_total > lh.scheduled_outstanding_total
               AND status in (6)
         #{group_by_query};})
  end
  
  # Gives loan defaulted for a particular object
  # For instance LoanHistory.defaulted_loan_info_for(Branch.first, Date.today, 10) gives back loans inside Branch.first defaulted by less than 10 days
  # For instance LoanHistory.defaulted_loan_info_for(Branch.first, Date.today) gives back loans inside Branch.first in default

  # loan_type here is relevant only for the case of staff member. This comes into play when we need all the loans under centers
  # managed by the staff member.
  def self.defaulted_loan_info_for(obj, date=Date.today, days=nil, type=:aggregate, loan_type = :created)    
    query =  get_query(obj, loan_type)
    query += " AND lh.days_overdue<=#{days}" if days

    # either we list or we aggregate depending on type
    if type==:listing
      select=%Q{
                 lh.loan_id, lh.branch_id, lh.center_id, lh.client_group_id, lh.client_id, lh.amount_in_default, lh.days_overdue as late_by, 
                 lh.actual_outstanding_total-lh.scheduled_outstanding_total total_due, lh.actual_outstanding_principal-lh.scheduled_outstanding_principal principal_due
               };
    else
      select = %Q{SUM(lh.actual_outstanding_total - lh.scheduled_outstanding_total) total_due, SUM(lh.actual_outstanding_principal - lh.scheduled_outstanding_principal) principal_due};
    end
      
    subtable = get_subtable(date, query)

    # These are the lines from the loan history
    query = %Q{
      SELECT #{select}
      FROM #{subtable} dt, loan_history lh, loans l
      WHERE lh.loan_id=dt.loan_id AND lh.date=dt.date AND lh.status in (5,6) AND lh.loan_id = l.id AND l.deleted_at is NULL
            AND lh.actual_outstanding_principal > lh.scheduled_outstanding_principal AND lh.actual_outstanding_total > lh.scheduled_outstanding_total}
    type==:listing ? repository.adapter.query(query) : repository.adapter.query(query).first
  end

  def self.sum_outstanding_by_group(from_date, to_date)
    sum_outstanding_grouped_by(to_date, [:center, :client_group], extra)
  end
  
  # Get loans for which there is some advance in balance
  # For instance we can group loans by [:branch, :center] or [:branch, :center, :client_group]
  # by saying LoanHistory.advance_balance(Date.today, [:branch, :center])

  # on can also restrict the scope of the query by providing 'query'
  # for instance, query = ["branch_id=3", "center_id=100"]
  def self.advance_balance(to_date, group_by, query=[], selects="")
    subtable       = get_subtable(to_date, query)
    group_by_query = get_group_by(group_by)
    selects        = get_selects(group_by, selects)
    
    repository.adapter.query(%Q{
      SELECT 
        SUM(lh.scheduled_outstanding_principal - lh.actual_outstanding_principal) AS balance_principal,
        SUM(lh.scheduled_outstanding_total - lh.actual_outstanding_total) AS balance_total,
        #{selects}
      FROM #{subtable} dt, loan_history lh, loans l
      WHERE lh.loan_id=dt.loan_id AND lh.date=dt.date AND lh.status in (5,6)
            AND lh.loan_id=l.id AND l.deleted_at is NULL
            AND lh.scheduled_outstanding_principal > lh.actual_outstanding_principal
            AND lh.scheduled_outstanding_total > lh.actual_outstanding_total
      #{group_by_query};
    })    
  end

  # Get total advance collected between a date range (from_date, to_date). This presentes the data in grouped by given group_by array
  # For instance we can group loans by [:branch, :center] or [:branch, :center, :client_group]
  # by saying LoanHistory.sum_advance_payment([:branch, :center], Date.today)
  # on can also restrict the scope of the query by providing 'extra_conditions'
  # for instance, extra_conditions = ["branch_id=3", "center_id=100"]
  def self.sum_advance_payment(from_date, to_date, group_by, extra_conditions=[], selects="")
    extra_conditions = "AND #{extra_conditions.join(' AND ')}" if extra_conditions.length>0
    group_by_query   = get_group_by(group_by)
    selects          = get_selects(group_by, selects)

    repository.adapter.query(%Q{
      SELECT 
        (-1 * SUM(lh.principal_due)) AS advance_principal,
        (-1 * (SUM(lh.principal_due) + SUM(lh.interest_due))) AS advance_total,
        #{selects}
      FROM loan_history lh, loans l
      WHERE lh.status in (6) AND l.id=lh.loan_id AND lh.date>='#{from_date.strftime('%Y-%m-%d')}' AND lh.date<='#{to_date.strftime('%Y-%m-%d')}'
            AND lh.scheduled_outstanding_principal > lh.actual_outstanding_principal AND lh.scheduled_outstanding_total > lh.actual_outstanding_total
            AND lh.principal_paid>0 AND lh.principal_due < 0 AND l.deleted_at is NULL #{extra_conditions}
      #{group_by_query};
    })
  end

  # TODO: subsitute the body of this function with sum_outstanding_grouped_by
  def self.sum_outstanding_by_center(from_date, to_date, extra)
    sum_outstanding_grouped_by(to_date, :center, extra)
  end

  # Get sum outstanding for all the loans grouped by given group_by array for a given date
  # For instance we can group loans by [:branch, :center] or [:branch, :center, :client_group]
  # by saying LoanHistory.sum_outstanding_grouped_by(Date.today, [:branch, :center])
  # on can also restrict the scope of the query by providing 'extra_condition'
  # for instance, extra_conditions = ["branch_id=3", "center_id=100"]
  def self.sum_outstanding_grouped_by(to_date, group_by, extra_conditions=[], selects = "")
    subtable       = get_subtable(to_date, extra_conditions)
    group_by_query = get_group_by(group_by)
    selects        = get_selects(group_by, selects)

    repository.adapter.query(%Q{
      SELECT 
        SUM(lh.scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(lh.scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(lh.actual_outstanding_principal)    AS actual_outstanding_principal,
        SUM(lh.actual_outstanding_total)        AS actual_outstanding_total,
        SUM(if(lh.actual_outstanding_principal<lh.scheduled_outstanding_principal, lh.scheduled_outstanding_principal-lh.actual_outstanding_principal,0)) AS advance_principal,
        SUM(if(lh.actual_outstanding_total<lh.scheduled_outstanding_total, lh.scheduled_outstanding_total-lh.actual_outstanding_total,0)) AS advance_total,
        COUNT(lh.loan_id) loan_count,
        #{selects}
      FROM #{subtable} as dt, loan_history lh, loans l
      WHERE lh.loan_id=dt.loan_id AND lh.date=dt.date AND lh.status in (5,6) AND lh.loan_id=l.id AND l.deleted_at is NULL AND l.rejected_on is NULL
      #{group_by_query};
    })
  end

  def self.sum_outstanding_by_month(month, year, branch, extra = [])
    date = Date.new(year, month, -1)
    extra << ["lh.branch_id=#{branch.id}"]    
    sum_outstanding_grouped_by(date, :branch, extra.join(" AND "))
  end

  # Get sum disbursed for all the loans grouped by given group_by array for a given date
  # For instance we can group loans by [:branch, :center] or [:branch, :center, :client_group]
  # by saying LoanHistory.sum_disbursed_grouped_by([:branch, :center], Date.today-100, Date.today)
  # on can also restrict the scope of the query by providing 'extra_condition'
  # for instance, extra_conditions = ["branch_id=3", "center_id=100"]
  def self.sum_disbursed_grouped_by(group_by, from_date=Date.min_date, to_date=Date.today, extra_conditions=[], selects="")
    group_by_query = get_group_by(group_by)
    selects        = get_selects(group_by, selects)
    extra          = build_extra(extra_conditions)

    repository.adapter.query(%Q{
      SELECT 
        SUM(l.amount) AS loan_amount,
        COUNT(lh.loan_id) loan_count,
        #{selects}
      FROM loan_history lh, loans l
      WHERE lh.status in (5) AND lh.loan_id=l.id AND l.deleted_at is NULL AND l.rejected_on is NULL
            AND lh.date <= '#{to_date.strftime('%Y-%m-%d')}' AND lh.date >= '#{from_date.strftime('%Y-%m-%d')}' #{extra}
      #{group_by_query};
    })
  end

  # Get sum applied for all the loans grouped by given group_by array for a given date
  # For instance we can group loans by [:branch, :center] or [:branch, :center, :client_group]
  # by saying LoanHistory.sum_approved_grouped_by([:branch, :center], Date.today-100, Date.today)
  # on can also restrict the scope of the query by providing 'extra_condition'
  # for instance, extra_conditions = ["branch_id=3", "center_id=100"]
  def self.sum_applied_grouped_by(group_by, from_date=Date.min_date, to_date=Date.today, extra_conditions=[], selects="")
    group_by_query = get_group_by(group_by).gsub("l.disbursed_by_staff_id", "l.applied_by_staff_id")
    selects        = get_selects(group_by, selects).gsub("l.disbursed_by_staff_id", "l.applied_by_staff_id")
    extra          = build_extra(extra_conditions)

    repository.adapter.query(%Q{
      SELECT 
        SUM(if(l.amount_applied_for>0, l.amount_applied_for, l.amount)) AS loan_amount,
        COUNT(lh.loan_id) loan_count,
        #{selects}
      FROM (SELECT max(lh.date) date, lh.loan_id loan_id
            FROM loan_history lh, loans l
            WHERE lh.loan_id=l.id AND l.deleted_at is NULL AND l.rejected_on is NULL
              AND lh.date<='#{to_date.strftime('%Y-%m-%d')}'
              AND l.applied_on >= '#{from_date.strftime('%Y-%m-%d')}' AND l.applied_on <= '#{to_date.strftime('%Y-%m-%d')}'
              #{extra}
            GROUP BY lh.loan_id)AS dt, loan_history lh, loans l
      WHERE lh.date=dt.date AND lh.loan_id=dt.loan_id AND lh.loan_id = l.id
      #{group_by_query};
    })
  end


  # Get sum approved for all the loans grouped by given group_by array for a given date
  # For instance we can group loans by [:branch, :center] or [:branch, :center, :client_group]
  # by saying LoanHistory.sum_approved_grouped_by([:branch, :center], Date.today-100, Date.today)
  # on can also restrict the scope of the query by providing 'extra_condition'
  # for instance, extra_conditions = ["branch_id=3", "center_id=100"]
  def self.sum_approved_grouped_by(group_by, from_date=Date.min_date, to_date=Date.today, extra_conditions=[], selects="")
    group_by_query = get_group_by(group_by).gsub("l.disbursed_by_staff_id", "l.approved_by_staff_id")
    selects        = get_selects(group_by, selects).gsub("l.disbursed_by_staff_id", "l.approved_by_staff_id")
    extra          = build_extra(extra_conditions)

    repository.adapter.query(%Q{
      SELECT 
        SUM(if(l.amount_sanctioned>0, l.amount_sanctioned, l.amount)) AS loan_amount,
        COUNT(lh.loan_id) loan_count,
        #{selects}
      FROM (SELECT max(lh.date) date, lh.loan_id loan_id
            FROM loan_history lh, loans l
            WHERE lh.loan_id=l.id AND l.deleted_at is NULL AND l.rejected_on is NULL
              AND lh.date<='#{to_date.strftime('%Y-%m-%d')}'
              AND l.approved_on >= '#{from_date.strftime('%Y-%m-%d')}' AND l.approved_on <= '#{to_date.strftime('%Y-%m-%d')}'
              #{extra}
            GROUP BY lh.loan_id)AS dt, loan_history lh, loans l
      WHERE lh.date=dt.date AND lh.loan_id=dt.loan_id AND lh.loan_id = l.id
      #{group_by_query};
    })
  end

  # Get sum repayment grouped by given group_by array for a given date
  # For instance we can group by [:branch, :center] or [:branch, :center, :client_group]
  # by saying LoanHistory.sum_repayment_grouped_by([:branch, :center], from_date, to_date)
  # on can also restrict the scope of the query by providing 'extra_condition'
  # for instance, extra_conditions = ["branch_id=3", "center_id=100"]
  def self.sum_repayment_grouped_by(group_by, from_date=Date.min_date, to_date=Date.today, extra_conditions=[], selects="")
    group_by_query = get_group_by(group_by)
    selects        = get_selects(group_by, selects)
    extra          = build_extra(extra_conditions)

    repository.adapter.query(%Q{
      SELECT 
        SUM(p.amount) AS amount,
        p.type type,
        #{selects}
      FROM loan_history lh, payments p
      WHERE lh.loan_id=p.loan_id AND p.deleted_at is NULL
            AND p.received_on <= '#{to_date.strftime('%Y-%m-%d')}' AND p.received_on >= '#{from_date.strftime('%Y-%m-%d')}' #{extra}
            AND p.received_on = lh.date
      #{group_by_query}, p.type;
    }).group_by{|x| Payment::PAYMENT_TYPES[x.type-1]}
  end

  # Gives loan outstanding for/under a particular object
  # For instance LoanHistory.sum_outstanding_for(Branch.first, Date.today) gives back loans disbursed under Branch.first
  # loan_type here is relevant only for the case of staff member. This comes into play when we need all the loans under centers
  # managed by the staff member.
  def self.sum_outstanding_for(obj, to_date=Date.today, loan_type = :created)
    if [Branch, Center, ClientGroup, Client].include?(obj.class)
      q = "lh.#{obj.class.name.snake_case}_id"
      query = "#{q}=#{obj.id}"
    elsif obj.class==Region or obj.class==Area
      ids = (obj.class==Region ? obj.areas.branches(:fields => [:id]).map{|x| x.id} : obj.branches(:fields => [:id]).map{|x| x.id})
      ids = (ids.length==0 ? "NULL" : ids.join(","))
      query="branch_id in (#{ids})"
    elsif obj.class==StaffMember
      if loan_type == :created
        ids = Loan.all(:fields => [:id], :disbursed_by_staff_id => obj.id).map{|x| x.id}
      elsif loan_type == :managed
        ids = Loan.all(:fields => [:id], "client.center.manager_staff_id" => obj.id).map{|x| x.id}
      end
      ids = (ids.length==0 ? "NULL" : ids.join(","))
      query="loan_id in (#{ids})"
      q = "lh.branch_id"
    elsif obj.class==LoanProduct
      query="l.loan_product_id = #{obj.id}"
    elsif obj.class==FundingLine
      query="l.funding_line_id = #{obj.id}"
    elsif obj==Mfi
      query="1"
    end
    group_by = q ? "GROUP BY #{q}" : " LIMIT 1"
    q = ", #{q}" if q

    subtable       = get_subtable(to_date, query)

    select  = %Q{
        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(if(actual_outstanding_principal>0, actual_outstanding_principal,0))    AS actual_outstanding_principal,
        SUM(if(actual_outstanding_total>0,     actual_outstanding_total, 0))        AS actual_outstanding_total,
        SUM(if(actual_outstanding_principal<0, actual_outstanding_principal,0))    AS advance_principal,
        SUM(if(actual_outstanding_total<0,     actual_outstanding_total,0))        AS advacne_total,
        COUNT(DISTINCT(lh.loan_id))             AS loans_count,
        COUNT(DISTINCT(lh.client_id))           AS clients_count
        #{q}
    }

    repository.adapter.query(%Q{
      SELECT #{select}
      FROM #{subtable} dt, loan_history lh, loans l
      WHERE  lh.loan_id=dt.loan_id AND lh.date=dt.date AND lh.loan_id = l.id AND l.deleted_at is NULL AND l.rejected_on is NULL
            AND lh.status in (5,6) AND lh.loan_id=l.id AND l.deleted_at is NULL AND l.rejected_on is NULL            
      #{group_by}
    })
  end

  # TODO:  rewrite it using Datamapper
  def self.loans_for(obj, hash={})
    select = "l.id id, l.amount amount, l.disbursal_date disbursal_date"
    klass, obj = get_class_of(obj)
    froms = build_froms(klass)
    conditions  = build_conditions(klass, obj, hash)
    repository.adapter.query("SELECT #{select} FROM #{froms.join(', ')} WHERE #{conditions.join(' AND ')}")
  end  

  # Gives loans outstanding for/under a particular object. Not be to confused with sum_outstanding_for which gives a aggregation. This provides listing.
  # For instance LoanHistory.loans_outstanding_for(Branch.first, Date.today) gives back loans outstanding under Branch.first on that date
  def self.loans_outstanding_for(obj, date=Date.today)
    klass, obj = get_class_of(obj)
    froms = build_froms(klass)
    conditions  = build_conditions(klass, obj, {})
    query    = get_query(obj)
    ids      = get_latest_rows_of_loans(date, query)
    return if ids.length == 0
    repository.adapter.query(%Q{
      SELECT
        lh.loan_id loan_id, l.amount   amount, l.disbursal_date disbursal_date,
        lh.scheduled_outstanding_principal AS scheduled_outstanding_principal, lh.scheduled_outstanding_total AS scheduled_outstanding_total,        
        lh.actual_outstanding_principal    AS actual_outstanding_principal, lh.actual_outstanding_total AS actual_outstanding_total
      FROM loan_history lh, #{froms.join(', ')}
      WHERE (lh.loan_id, lh.date) in (#{ids}) AND lh.loan_id=l.id AND lh.status in (5,6) AND #{conditions.join(' AND ')}
    })    
  end

  # Gives loans outstanding for/under a particular object. Not be to confused with sum_outstanding_for which gives a aggregation. This provides listing.
  # For instance LoanHistory.loans_outstanding_for(Branch.first, Date.today) gives back loans outstanding under Branch.first on that date
  # loan_type here is relevant only for the case of staff member. This comes into play when we need all the loans under centers
  # managed by the staff member.
  def self.amount_disbursed_for(obj, from_date=Date.min_date, to_date=Date.today, loan_type = :created)
    hash = {:status => :disbursed, "loan.deleted_at" => nil, :date.gte => from_date, :date.lte => to_date}
    if obj.class == StaffMember and loan_type == :created
      hash["loan.disbursed_by_staff_id"] = obj.id
    elsif obj.class == StaffMember and loan_type == :managed
      hash["loan.client.center.manager_staff_id"] = obj.id
    elsif obj.class == LoanProduct
      hash["loan.loan_product_id"] = obj.id
    elsif obj.class == FundingLine
      hash["loan.funding_line_id"] = obj.id
    elsif obj.class == Region
      hash[:branch_id] = obj.areas.branches.map{|b| b.id}
    elsif obj.class == Area
      hash[:branch_id] = obj.branches.map{|b| b.id}
    else
      hash["#{obj.class.to_s.snake_case}_id".to_sym] = (obj.is_a?(Array) ? obj.map{|x| x.id} : obj.id)
    end

    data = LoanHistory.all(hash).aggregate(:scheduled_outstanding_principal.sum, :loan_id.count)
    Struct.new(:client_count, :loan_count, :amount).new(LoanHistory.all(hash).aggregate(:client_id).count, data[1], data[0])
  end

  # TODO:  rewrite it using Datamapper
  def self.borrower_clients_count_in(obj, hash={})
    klass, obj = get_class_of(obj)
    froms = build_froms(klass)
    conditions  = build_conditions(klass, obj, hash)
    repository.adapter.query("SELECT count(*) FROM #{froms.join(', ')} WHERE #{conditions.join(' AND ')}")
  end

  # returns back which ids of the objects of klass which are attached to loans restricted by 'hash'
  # for instance LoanHistory.parents_where_loans_of(Branch, {:loan_product_id => 4})
  # finds all the branch ids where loans of loan product id 4 has been disbursed.
  def self.parents_where_loans_of(klass, hash)
    selects    = build_selects(klass)
    froms      = build_froms(klass)
    conditions = build_conditions(klass, klass.all(hash[klass.to_s.snake_case.to_sym]), hash)
    repository.adapter.query("SELECT #{selects} FROM #{froms.join(', ')} WHERE #{conditions.join(' AND ')}")
  end
  
  # returns back which ids of the objects of ancestor_klass which are attached to portfolio
  # for instance LoanHistory.ancestors_of_portfolio(Portfolio.first, Branch.first)
  # this will find all the loans in the give 'Poritfolio.first' and traverse up the hierarchy to find all branches reachable from these loans
  # 'portfolio' can also be an array containing multiple portfolios
  def self.ancestors_of_portfolio(portfolio, ancestor_klass, hash={})
    portfolio_klass, obj = get_class_of(portfolio)
    selects    = build_selects(ancestor_klass)
    froms      = ((build_froms(ancestor_klass)||[]) + (build_froms(portfolio_klass)||[])).uniq
    conditions = (build_conditions(ancestor_klass, nil, hash) + build_conditions(portfolio_klass, obj, hash))
    repository.adapter.query("SELECT #{selects} FROM #{froms.join(', ')} WHERE #{conditions.join(' AND ')}")
  end
  
  def self.payment_due_by_center(date, hash)
    hash[:date.lt] = Date.today
    last_due_dates_query = LoanHistory.all(hash).aggregate(:center_id, :date.max).map{|x| "(#{x[0]}, '#{x[1].strftime('%Y-%m-%d')}')"}.join(", ")
    return [] if last_due_dates_query.length==0

    repository.adapter.query(%Q{
      SELECT SUM(lh.principal_due) principal_due, SUM(lh.interest_due) interest_due, branch_id, center_id
      FROM loan_history lh, loans l
      WHERE (lh.center_id, lh.date) in (#{last_due_dates_query}) AND lh.status in (5,6) AND lh.loan_id=l.id AND l.deleted_at is NULL
      GROUP BY center_id
    })
  end

  # Given back loan repaid count for an object.
  # loan_type here is relevant only for the case of staff member. This comes into play when we need all the loans under centers
  # managed by the staff member.
  def self.loan_repaid_count(obj, from_date=Date.min_date, to_date=Date.today, loan_type = :created) 
    hash = {:status => :repaid, :date.gte => from_date, :date.lte => to_date, "loan.deleted_at" => nil}
    if obj.class == StaffMember
      if loan_type == :created
        hash["loan.disbursed_by_staff_id"] = obj.id
      else        
        if obj.centers(:fields => [:id]).count > 0
          hash["center_id"] = obj.centers(:fields => [:id]).map{|x| x.id}
        else
          return 0
        end
      end
    elsif obj.class == FundingLine
      hash["loan.funding_line_id"] = obj.id
    elsif obj.class == LoanProduct
      hash["loan.loan_product_id"] = obj.id
    elsif obj.class == Region
      hash[:branch_id] = obj.areas.branches.map{|b| b.id}
    elsif obj.class == Area
      hash[:branch_id] = obj.branches.map{|b| b.id}
    else
      hash["#{obj.class.to_s.snake_case}_id".to_sym] = (obj.is_a?(Array) ? obj.map{|x| x.id} : obj.id)
    end
    LoanHistory.all(hash).aggregate(:loan_id.count)
  end

  # group loans which have been repaid. 
  def self.sum_repaid_grouped_by(group_by, from_date, to_date, extra=[], selects="")
    group_by_query = get_group_by(group_by)
    selects  = get_selects(group_by, selects)
    extra    = build_extra(extra)

    repository.adapter.query(%Q{
      SELECT 
        SUM(l.amount) AS loan_amount,
        COUNT(DISTINCT(lh.loan_id)) loan_count,
        #{selects}
      FROM loan_history lh, loans l
      WHERE lh.status in (7) AND lh.loan_id=l.id AND l.deleted_at is NULL AND l.rejected_on is NULL
            AND lh.date <= '#{to_date.strftime('%Y-%m-%d')}' AND lh.date >= '#{from_date.strftime('%Y-%m-%d')}' #{extra}
      #{group_by_query};
    })    
  end

  # group loans which have been foreclosed. 
  def self.sum_foreclosure_grouped_by(group_by, from_date, to_date, extra=[], selects="")
    group_by_query = get_group_by(group_by)
    selects        = get_selects(group_by, selects)
    extra          = build_extra(extra)

    repository.adapter.query(%Q{
      SELECT
        SUM(lh.actual_outstanding_principal) AS loan_amount,
        COUNT(lh.loan_id) loan_count,
        #{selects}
      FROM (SELECT max(lh.date) date, lh.loan_id loan_id
            FROM loan_history lh, loans l
            WHERE lh.loan_id=l.id AND l.deleted_at is NULL AND lh.status IN (7) AND lh.date<='#{to_date.strftime('%Y-%m-%d')}'
                  AND lh.scheduled_outstanding_total > 0 AND lh.scheduled_outstanding_principal > 0 #{extra}
            GROUP BY lh.loan_id
            ) dt, loan_history lh, loans l
      WHERE lh.loan_id=dt.loan_id AND lh.date = dt.date AND lh.date <= '#{to_date.strftime('%Y-%m-%d')}' AND lh.date >= '#{from_date.strftime('%Y-%m-%d')}'
            AND lh.loan_id=l.id AND l.deleted_at is NULL #{extra}
      #{group_by_query};
    })    
  end

  # group loans which have been written off. 
  def self.sum_written_off_grouped_by(group_by, from_date, to_date, extra=[], selects="")
    group_by_query = get_group_by(group_by)
    selects        = get_selects(group_by, selects)
    extra          = build_extra(extra)

    repository.adapter.query(%Q{
      SELECT
        SUM(lh.actual_outstanding_principal) AS loan_amount,
        COUNT(lh.loan_id) loan_count,
        #{selects}
      FROM (SELECT max(lh.date) date, lh.loan_id loan_id
            FROM loan_history lh, loans l
            WHERE lh.loan_id=l.id AND l.deleted_at is NULL AND lh.status IN (8) AND lh.date<='#{to_date.strftime('%Y-%m-%d')}' #{query}
            GROUP BY lh.loan_id
            ) dt, loan_history lh, loans l
      WHERE lh.loan_id=dt.loan_id AND lh.date = dt.date AND lh.date <= '#{to_date.strftime('%Y-%m-%d')}' AND lh.date >= '#{from_date.strftime('%Y-%m-%d')}'
            AND lh.loan_id=l.id AND l.deleted_at is NULL #{extra}
      #{group_by_query};
    })    
  end

  # group loans which have been claimed. 
  def self.sum_claimed_grouped_by(group_by, from_date, to_date, extra=[], selects="")
    group_by_query = get_group_by(group_by)
    selects        = get_selects(group_by, selects)
    extra          = build_extra(extra)

    repository.adapter.query(%Q{
      SELECT
        SUM(lh.actual_outstanding_principal) AS loan_amount,
        COUNT(lh.loan_id) loan_count,
        #{selects}
      FROM (SELECT max(lh.date) date, lh.loan_id loan_id
            FROM loan_history lh, loans l
            WHERE lh.loan_id=l.id AND l.deleted_at is NULL AND lh.status IN (9) AND lh.date<='#{to_date.strftime('%Y-%m-%d')}' #{query}
            GROUP BY lh.loan_id
            ) dt, loan_history lh, loans l
      WHERE lh.loan_id=dt.loan_id AND lh.date = dt.date AND lh.date <= '#{to_date.strftime('%Y-%m-%d')}' AND lh.date >= '#{from_date.strftime('%Y-%m-%d')}'
            AND lh.loan_id=l.id AND l.deleted_at is NULL #{extra}
      #{group_by_query};
    })    
  end

  private
  def self.get_class_of(obj)
    if [Array, DataMapper::Associations::OneToMany::Collection, DataMapper::Associations::ManyToMany::Collection, DataMapper::Collection].include?(obj.class)
      klass = obj.first.class 
    else
      klass = obj.class
      obj   = [obj]
    end
    klass = Loan if not @@models.include?(klass) and (klass.superclass==Loan or klass.superclass.superclass==Loan)
    [klass, obj]
  end
  
  def self.build_selects(klass)
    "distinct(#{@@selects[klass]})"
  end
    
  def self.build_froms(klass)
    froms  = []
    return ["loans l", "clients cl"] if klass == StaffMember or klass == Loan or klass == LoanProduct
    return ["loans l", "portfolios p", "portfolio_loans pfl"] if klass == Portfolio
    klass = Client if klass == FundingLine
    return false unless @@models.include?(klass)

    idx    = @@models.index(klass)
    (if klass == ClientGroup or idx > 4
       @@tables[idx..-1]
     else
       (@@tables - ["client_groups cg"])[idx..-1]
     end).each{|table|
      froms << table
    }
    froms
  end


  # TODO:  rewrite it for Datamapper
  def self.build_conditions(klass, obj, hash={})
    # lets save some memory if we have to only get ids
    obj = obj.all(:fields => [:id]) if obj and obj.class != Array

    conditions =  ["cl.id=l.client_id", "l.deleted_at is NULL"] 
    if hash.length>0
      report = Report.new
      {:loan => "l", :client => "cl", :center =>  "c", :branch => "b"}.each{|model, prefix|
        conditions += hash[model].map{|k, v| 
          "#{prefix}.#{report.get_key(k)} #{report.get_operator(k, v)} #{report.get_value(v)}"
        } if hash.key?(model) and hash[model]
      }
    end
    
    conditions << "cl.center_id=c.id" if [Branch, Center, Area, Region].include?(klass)
    conditions << "c.branch_id=b.id"  if [Branch, Area, Region].include?(klass)
    conditions << "a.id=b.area_id"    if [Area, Region].include?(klass)

    if klass==Branch
      conditions << "b.id in (#{obj.map{|x| x.id}.join(',')})" if obj and obj.length>0
    elsif klass==Center
      conditions << "c.id in (#{obj.map{|x| x.id}.join(',')})" if obj and obj.length > 0
    elsif klass==ClientGroup
      conditions << "cl.client_group_id=cg.id"
      conditions << "cg.id in (#{obj.map{|x| x.id}.join(',')})" if obj and obj.length > 0
    elsif klass==Area
      conditions << "a.id in (#{obj.map{|x| x.id}.join(',')})" if obj and obj.length > 0
    elsif klass==Region
      conditions << "r.id in (#{obj.map{|x| x.id}.join(',')})" if obj and obj.length > 0
      conditions << "r.id=a.region_id"
    elsif klass==Client
      conditions << "cl.id in (#{obj.map{|x| x.id}.join(',')})" if obj and obj.length > 0
    elsif klass==StaffMember
      conditions <<  "l.disbursed_by_staff_id in (#{obj.map{|x| x.id}.join(',')})" if obj
    elsif klass==Loan
      conditions <<  "l.id in (#{obj.map{|x| x.id}.join(',')})" if obj
    elsif klass==LoanProduct
      conditions <<  "l.loan_product_id in (#{obj.map{|x| x.id}.join(',')})" if obj
    elsif klass==Portfolio
      conditions = []
      conditions << "p.id in (#{obj.map{|x| x.id}.join(',')})" if obj
      conditions << "pfl.portfolio_id = p.id"
      conditions << "pfl.active = 1"
      conditions << "l.id = pfl.loan_id"
    elsif klass==FundingLine
      conditions <<  "l.funding_line_id in (#{obj.map{|x| x.id}.join(',')})" if obj
    end
    conditions
  end

  # TODO:  rewrite it using Datamapper
  def self.get_latest_rows_of_loans(date = Date.today, query="1")
    query = build_extra(query)
    repository.adapter.query(%Q{
                                 SELECT lh.loan_id loan_id, max(lh.date) mdate
                                 FROM loan_history lh, loans l
                                 WHERE lh.status in (5,6,7,8) AND lh.date<='#{date.strftime('%Y-%m-%d')}' AND l.id=lh.loan_id AND l.deleted_at is NULL 
                                       #{query}
                                 GROUP BY lh.loan_id
                                 }).collect{|x| "(#{x.loan_id}, '#{x.mdate.strftime('%Y-%m-%d')}')"}.join(",")
  end

  def self.build_extra(query)
    query = query.to_a.map{|k, v| 
      if v.is_a?(Array) and v.length == 0
        "#{k} in (NULL)"
      elsif v.is_a?(Array)
        "#{k} in (#{v.join(", ")})"
      else
        "#{k}=#{v}"
      end
    }.join(" AND ") if query.is_a?(Hash)
    query = query.join(" AND ") if query.is_a?(Array)
    query = "1" if query.blank?
    " AND " + query
  end

  # returns the subquery which can be used elsewhere
  # loan_type here is relevant only for the case of staff member. This comes into play when we need all the loans under centers
  # managed by the staff member.
  def self.get_query(obj, loan_type=:created)
    if [Branch, Center, ClientGroup].include?(obj.class)
      "lh.#{obj.class.to_s.snake_case}_id=#{obj.id}"
    elsif obj.class==Region
      ids = obj.areas.branches({:fields => [:id]}).map{|x| x.id}
      ids = (ids.length==0 ? "NULL" : ids.join(","))
      "lh.branch_id in (#{ids})"
    elsif obj.class == Area
      ids = obj.branches({:fields => [:id]}).map{|x| x.id}
      ids = (ids.length==0 ? "NULL" : ids.join(","))
      "lh.branch_id in (#{ids})"      
    elsif obj.class==StaffMember
      if loan_type == :created
        "l.disbursed_by_staff_id= #{obj.id}"
      elsif loan_type == :managed
        ids = obj.centers.map{|x| x.id}      
        ids = (ids.length==0 ? "NULL" : ids.join(","))
        "lh.loan_id in (#{ids})"
      end
    elsif obj.class == FundingLine
      "l.funding_line_id = #{obj.id}"
    elsif obj.class == LoanProduct
      "l.loan_product_id = #{obj.id}"
    elsif obj == Mfi
      "1"
    end
  end
  
  # gives back group by clause for SQL GROUP BY
  def self.get_group_by(group_by)
    group_by = get_columns(group_by)
    group_by ? "GROUP BY #{group_by.gsub("date_id", "date").gsub("lh.staff_member_id", "l.disbursed_by_staff_id")}" : ""
  end

  def self.get_selects(group_by, selects)
    selects  = get_columns(selects)
    selects  = (selects + ", ") if selects and selects.length > 0
    selects += get_columns(group_by)
    selects
  end

  def self.get_columns(group_by)
    if group_by.class==String or group_by.class==Symbol
      group_by = group_by.to_s
      group_by = 
        if LoanHistory.properties.map{|x| x.name.to_s}.include?(group_by)
          "lh.#{group_by}"
        elsif LoanHistory.properties.map{|x| x.name.to_s}.include?("#{group_by}_id")
          "lh.#{group_by}_id"
        elsif Loan.properties.map{|x| x.name.to_s}.include?(group_by)
          "l.#{group_by}"
        elsif Loan.properties.map{|x| x.name.to_s}.include?("#{group_by}_id")
          "l.#{group_by}_id"
        elsif group_by.to_s == "staff_member" or group_by.to_s == "staff_member_id"
          "l.disbursed_by_staff_id"
        else
          group_by
        end
    elsif group_by.class==Array
      group_by = group_by.map{|x| get_columns(x)}.join(", ")
    else
      "1"
    end
    return group_by
  end

  def self.get_subtable(date, query)
    query = build_extra(query)    
    return "(SELECT max(lh.date) date, lh.loan_id loan_id
     FROM loan_history lh, loans l
     WHERE lh.loan_id=l.id AND l.deleted_at is NULL AND lh.status IN (5,6,7,8,9) AND lh.date<='#{date.strftime('%Y-%m-%d')}' #{query}
     GROUP BY lh.loan_id
     )"
  end

end
