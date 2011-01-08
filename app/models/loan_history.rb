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

  def self.defaulted_loan_info (days = 7, date = Date.today, query ={})
    # this does not work as expected if the loan is repaid and goes back into default within the days we are looking at it.
    defaulted_loan_ids = repository.adapter.query(%Q{
      SELECT loan_id FROM
        (SELECT loan_id, max(ddiff) as diff 
         FROM (SELECT date, loan_id, datediff(now(),date) as ddiff,actual_outstanding_principal - scheduled_outstanding_principal as diff 
               FROM loan_history 
               WHERE actual_outstanding_principal != scheduled_outstanding_principal and date < now()) as dt group by loan_id having diff < #{days}) as dt1;})
  end

  def self.defaulted_loan_info_by(group_by, date = Date.today, query={}, selects=[])
    # this does not work as expected if the loan is repaid and goes back into default within the days we are looking at it.
    selects << "#{group_by}_id"
    ids  = get_latest_rows_of_loans(date, query)
    return [] if ids.length==0
    repository.adapter.query(%Q{
         SELECT SUM(actual_outstanding_principal - scheduled_outstanding_principal) as pdiff, 
                SUM(actual_outstanding_total - scheduled_outstanding_total) as tdiff, 
                #{selects.uniq.join(',')}
         FROM loan_history 
         WHERE actual_outstanding_principal > scheduled_outstanding_principal AND actual_outstanding_total > scheduled_outstanding_total
               AND (loan_id, date) in (#{ids}) AND status in (5,6)
         GROUP BY #{group_by}_id;})
  end
  
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
      
    rows = get_latest_rows_of_loans(date, query)
    # these are the loan history lines which represent the last line before @date
    return nil if rows.length == 0

    # These are the lines from the loan history
    query = %Q{
      SELECT #{select}
      FROM loan_history lh, loans l
      WHERE (lh.loan_id, lh.date) IN (#{rows}) AND lh.status in (5,6) AND lh.loan_id = l.id AND l.deleted_at is NULL
            AND lh.actual_outstanding_principal > lh.scheduled_outstanding_principal AND lh.actual_outstanding_total > lh.scheduled_outstanding_total}
    type==:listing ? repository.adapter.query(query) : repository.adapter.query(query).first
  end

  # TODO: subsitute the body of this function with sum_outstanding_grouped_by
  def self.sum_outstanding_by_group(from_date, to_date)
    sum_outstanding_grouped_by(to_date, [:center, :client_group], extra)
  end
  
  def self.advance_balance(to_date, group_by, extra=[])
    ids = get_latest_rows_of_loans(to_date, extra)
    return false if ids.length==0
    
    repository.adapter.query(%Q{
      SELECT 
        SUM(scheduled_outstanding_principal-actual_outstanding_principal) AS balance_principal,
        SUM(scheduled_outstanding_total-actual_outstanding_total) AS balance_total,
        #{group_by}_id
      FROM loan_history
      WHERE (loan_id, date) in (#{ids}) AND status in (5,6)
            AND scheduled_outstanding_principal>actual_outstanding_principal AND scheduled_outstanding_total>actual_outstanding_total
      GROUP BY #{group_by}_id;
    })    
  end

  def self.sum_advance_payment(from_date, to_date, group_by, extra=[])
    extra = "AND #{extra.join(' AND ')}" if extra.length>0
    group_by = get_group_by(group_by)

    repository.adapter.query(%Q{
      SELECT 
        (-1 * MIN(lh.principal_due)) AS advance_principal,
        (-1 * (MIN(lh.principal_due) + MIN(lh.interest_due))) AS advance_total,
        #{group_by}
      FROM loan_history lh, loans l
      WHERE lh.status in (5, 6) AND l.id=lh.loan_id AND lh.date>='#{from_date.strftime('%Y-%m-%d')}' AND lh.date<='#{to_date.strftime('%Y-%m-%d')}'
            AND lh.scheduled_outstanding_principal > lh.actual_outstanding_principal AND lh.scheduled_outstanding_total > lh.actual_outstanding_total
            AND lh.principal_paid>0 AND l.deleted_at is NULL #{extra}
      GROUP BY #{group_by};
    })
  end

  # TODO: subsitute the body of this function with sum_outstanding_grouped_by
  def self.sum_outstanding_by_center(from_date, to_date, extra)
    sum_outstanding_grouped_by(to_date, :center, extra)
  end

  def self.sum_outstanding_grouped_by(to_date, group_by, extra=[], selects = "")
    ids = get_latest_rows_of_loans(to_date, extra)
    return [] if ids.length==0
    group_by = get_group_by(group_by)
    selects  = ", " + selects unless selects.blank?

    repository.adapter.query(%Q{
      SELECT 
        SUM(lh.scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(lh.scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(lh.actual_outstanding_principal)    AS actual_outstanding_principal,
        SUM(lh.actual_outstanding_total)        AS actual_outstanding_total,
        SUM(if(lh.actual_outstanding_principal<lh.scheduled_outstanding_principal, lh.scheduled_outstanding_principal-lh.actual_outstanding_principal,0)) AS advance_principal,
        SUM(if(lh.actual_outstanding_total<lh.scheduled_outstanding_total, lh.scheduled_outstanding_total-lh.actual_outstanding_total,0)) AS advance_total,
        COUNT(lh.loan_id) loan_count,
        #{group_by}
        #{selects}
      FROM loan_history lh, loans l
      WHERE (lh.loan_id, lh.date) in (#{ids}) AND lh.status in (5,6) AND lh.loan_id=l.id AND l.deleted_at is NULL
      GROUP BY #{group_by};
    })
  end

  def self.sum_outstanding_by_month(month, year, branch, extra = [])
    date = Date.new(year, month, -1)
    extra << ["lh.branch_id=#{branch.id}"]    
    sum_outstanding_grouped_by(date, :branch, extra.join(" AND "))
  end

  # TODO:  rewrite it using Datamapper
  def self.sum_disbursed_grouped_by(klass, conditions = {}, from_date=Date.min_date, to_date=Date.today)
    conditions[:loan] ||= {}
    conditions[:loan] +=  {:disbursal_date.gte => from_date, :disbursal_date.lte => to_date}
    group_id  = @@selects[klass]
    select    = "#{group_id}, SUM(l.amount) amount"
    klass, obj = get_class_of(klass.all)
    froms = build_froms(klass)
    conditions  = build_conditions(klass, nil, conditions)
    repository.adapter.query("SELECT #{select} FROM #{froms.join(', ')} WHERE #{conditions.join(' AND ')} GROUP BY #{group_id}")
  end

  # loan_type here is relevant only for the case of staff member. This comes into play when we need all the loans under centers
  # managed by the staff member.
  def self.sum_outstanding_for(obj, to_date=Date.today, loan_type = :created)
    if [Branch, Center, ClientGroup, Client].include?(obj.class)
      q = "lh.#{obj.class.name.snake_case}_id"
      query = "#{q}=#{obj.id}"
    elsif obj.class==Region or obj.class==Area
      ids = (obj.class==Region ? obj.areas.branches(:fields => [:id]).map{|x| x.id} : obj.branches(:fields => [:id]).map{|x| x.id})
      ids = (ids.length==0 ? "NULL" : ids.join(","))
      q = "lh.branch_id"
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

    ids = get_latest_rows_of_loans(to_date, query)
    return false if ids.length==0

    select  = %Q{
        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(if(actual_outstanding_principal>0, actual_outstanding_principal,0))    AS actual_outstanding_principal,
        SUM(if(actual_outstanding_total>0,     actual_outstanding_total, 0))        AS actual_outstanding_total,
        SUM(if(actual_outstanding_principal<0, actual_outstanding_principal,0))    AS advance_principal,
        SUM(if(actual_outstanding_total<0,     actual_outstanding_total,0))        AS advacne_total,
        COUNT(DISTINCT(loan_id))             AS loans_count,
        COUNT(DISTINCT(client_id))           AS clients_count
        #{q}
    }

    repository.adapter.query(%Q{
      SELECT #{select}
      FROM loan_history lh
      WHERE (lh.loan_id, lh.date) in (#{ids}) AND lh.status in (5,6)
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

  # TODO:  rewrite it using Datamapper
  def self.parents_where_loans_of(klass, hash)
    selects    = build_selects(klass)
    froms      = build_froms(klass)
    conditions = build_conditions(klass, klass.all(hash[klass.to_s.snake_case.to_sym]), hash)
    repository.adapter.query("SELECT #{selects} FROM #{froms.join(', ')} WHERE #{conditions.join(' AND ')}")
  end
  
  # TODO:  rewrite it using Datamapper
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
    repository.adapter.query(%Q{
                                 SELECT lh.loan_id loan_id, max(lh.date) mdate
                                 FROM loan_history lh, loans l
                                 WHERE lh.status in (5,6,7,8) AND lh.date<='#{date.strftime('%Y-%m-%d')}' AND l.id=lh.loan_id AND l.deleted_at is NULL 
                                       AND #{query}
                                 GROUP BY lh.loan_id
                                 }).collect{|x| "(#{x.loan_id}, '#{x.mdate.strftime('%Y-%m-%d')}')"}.join(",")
  end

  def self.get_group_by(group_by)
    if group_by.class==String
      group_by = group_by+"_id"
    elsif group_by.class==Array
      group_by = group_by.map{|x| "#{x}_id"}.join(", ")
    elsif group_by.class==Symbol
      group_by = "#{group_by}_id"
    else
      return false
    end
    group_by.gsub("date_id", "date")
  end

  # returns the subquery which can be used elsewhere

  # loan_type here is relevant only for the case of staff member. This comes into play when we need all the loans under centers
  # managed by the staff member.
  def self.get_query(obj, loan_type)
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
end
