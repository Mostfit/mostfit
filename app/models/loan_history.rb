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
      next if lh.client_group_id or not lh.client_id # what happens if group is changed?
      
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

  
  # __DEPRECATED__ the prefered way to make history and future.
  # HISTORY IS NOW WRITTEN BY THE LOAN MODEL USING update_history_bulk_insert

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

  def self.sum_outstanding_for_loans(date, loan_ids)
    repository.adapter.query(%Q{
      SELECT
        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(actual_outstanding_principal)    AS actual_outstanding_principal,
        SUM(actual_outstanding_total)        AS actual_outstanding_total
      FROM
      (select scheduled_outstanding_principal,scheduled_outstanding_total, actual_outstanding_principal, actual_outstanding_total from
        (select loan_id, max(date) as date from loan_history where date <= '#{date.strftime('%Y-%m-%d')}' and loan_id in (#{loan_ids.join(', ')}) and status in (5,6,7,8) group by loan_id) as dt, 
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

  def self.defaulted_loan_info_by(group_by, date = Date.today, query ={})
    # this does not work as expected if the loan is repaid and goes back into default within the days we are looking at it.
    repository.adapter.query(%Q{
         SELECT sum(pdiff) principal, sum(tdiff) total FROM
         (SELECT actual_outstanding_principal - scheduled_outstanding_principal as pdiff, 
                actual_outstanding_total - scheduled_outstanding_total as tdiff,
                #{group_by}_id
         FROM loan_history 
         WHERE actual_outstanding_principal != scheduled_outstanding_principal 
         AND current=1
         AND date <= '#{date.strftime("%Y-%m-%d")}') as dt WHERE pdiff>0 AND tdiff>0  GROUP BY #{group_by}_id;})
  end
  
  def self.defaulted_loan_info_for(obj, date=Date.today, type=:aggregate)
    if obj.class==Branch
      query = "branch_id=#{obj.id}"
    elsif obj.class==Center
      query = "center_id=#{obj.id}"
    elsif obj.class==ClientGroup
      query = "client_group_id=#{obj.id}"
    elsif obj.class==Region or obj.class==Area      
      ids = (obj.class==Region ? obj.areas : obj).send(:branches, {:fields => [:id]}).map{|x| x.id}
      ids = (ids.length==0 ? "NULL" : ids.join(","))
      query="branch_id in (#{ids})"
    elsif obj.class==StaffMember
      ids = Loan.all(:fields => [:id], :disbursed_by_staff_id => obj.id).map{|x| x.id}
      ids = (ids.length==0 ? "NULL" : ids.join(","))
      query = "loan_id in (#{ids})"
    end
    
    # either we list or we aggregate depending on type
    if type==:listing
      select = %Q{
                   loan_id, branch_id, center_id, client_group_id, client_id, amount_in_default, days_overdue as late_by, 
                   actual_outstanding_total-scheduled_outstanding_total total_due, actual_outstanding_principal-scheduled_outstanding_principal principal_due
               };
    else
      select = %Q{
                   SUM(actual_outstanding_total-scheduled_outstanding_total) total_due, SUM(actual_outstanding_principal-scheduled_outstanding_principal) principal_due
               };
    end
      
    ids=repository.adapter.query(%Q{
                                 SELECT lh.loan_id loan_id, max(lh.date) date
                                 FROM loan_history lh
                                 WHERE lh.status in (5,6,7,8) AND lh.date<='#{date.strftime('%Y-%m-%d')}' AND #{query}
                                 GROUP BY lh.loan_id
                                 }).collect{|x| "(#{x.loan_id}, '#{x.date.strftime('%Y-%m-%d')}')"}.join(",")    
    # these are the loan history lines which represent the last line before @date
    return nil if ids.length == 0
    rows = repository.adapter.query(%Q{
      SELECT loan_id,max(date)
      FROM loan_history
      WHERE amount_in_default > 0 and status in (5,6,7,8) and (loan_id, date) in (#{ids})
      GROUP BY loan_id})
    return nil if rows and rows.length==0

    # These are the lines from the loan history
    query = %Q{
      SELECT #{select}
      FROM loan_history
      WHERE (loan_id,date) IN (#{rows.map{|x| "(#{x[0]}, '#{x[1].strftime("%Y-%m-%d")}')"}.join(',')})
      ORDER BY branch_id, center_id}
    repository.adapter.query(query).first
  end

  # TODO: subsitute the body of this function with sum_outstanding_grouped_by
  def self.sum_outstanding_by_group(from_date, to_date, loan_product_id=nil)
    extra, from = "", "loan_history lh"
    if loan_product_id and loan_product_id.to_i>0
      extra = "AND lh.loan_id=l.id AND l.loan_product_id=#{loan_product_id}"
      from += ", loans l"
    end
    ids=repository.adapter.query(%Q{
                                 SELECT lh.loan_id loan_id, max(lh.date) date
                                 FROM #{from}
                                 WHERE lh.status in (5,6,7,8) AND lh.date>='#{from_date.strftime('%Y-%m-%d')}' 
                                 AND lh.date<='#{to_date.strftime('%Y-%m-%d')}' #{extra}
                                 GROUP BY lh.loan_id
                                 }).collect{|x| "(#{x.loan_id}, '#{x.date.strftime('%Y-%m-%d')}')"}.join(",")
    return false if ids.length==0
    
    repository.adapter.query(%Q{
      SELECT 
        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(actual_outstanding_principal)    AS actual_outstanding_principal,
        SUM(actual_outstanding_total)        AS actual_outstanding_total,
        SUM(if(actual_outstanding_principal<scheduled_outstanding_principal,  scheduled_outstanding_principal-actual_outstanding_principal,0)) AS advance_principal,
        SUM(if(actual_outstanding_total<scheduled_outstanding_total,          scheduled_outstanding_total-actual_outstanding_total,0))         AS advance_total,
        client_group_id,
        center_id
      FROM loan_history
      WHERE (loan_id, date) in (#{ids}) AND status in (5,6)
      GROUP BY client_group_id;
    })
  end

  # TODO: subsitute the body of this function with sum_outstanding_grouped_by
  def self.sum_outstanding_by_center(from_date, to_date, loan_product_id=nil)
    extra, from = "", "loan_history lh"
    if loan_product_id and loan_product_id.to_i>0
      extra = "AND lh.loan_id=l.id AND l.loan_product_id=#{loan_product_id}"
      from += ", loans l"
    end
    ids=repository.adapter.query(%Q{
                                 SELECT lh.loan_id loan_id, max(lh.date) date
                                 FROM #{from}
                                 WHERE lh.status in (5,6,7,8) AND lh.date>='#{from_date.strftime('%Y-%m-%d')}' 
                                 AND lh.date<='#{to_date.strftime('%Y-%m-%d')}' #{extra}
                                 GROUP BY lh.loan_id
                                 }).collect{|x| "(#{x.loan_id}, '#{x.date.strftime('%Y-%m-%d')}')"}.join(",")
    return false if ids.length==0
    
    repository.adapter.query(%Q{
      SELECT 
        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(actual_outstanding_principal)    AS actual_outstanding_principal,
        SUM(actual_outstanding_total)        AS actual_outstanding_total,
        SUM(if(actual_outstanding_principal<scheduled_outstanding_principal,  scheduled_outstanding_principal-actual_outstanding_principal,0)) AS advance_principal,
        SUM(if(actual_outstanding_total<scheduled_outstanding_total,          scheduled_outstanding_total-actual_outstanding_total,0))         AS advance_total,
        center_id
      FROM loan_history
      WHERE (loan_id, date) in (#{ids}) AND status in (5,6)
      GROUP BY center_id;
    })
  end

  def self.sum_outstanding_grouped_by(to_date, group_by, loan_product_id=nil)
    extra, from = "", "loan_history lh"
    if loan_product_id and loan_product_id.to_i>0
      extra = "AND lh.loan_id=l.id AND l.loan_product_id=#{loan_product_id}"
      from += ", loans l"
    end
    ids=repository.adapter.query(%Q{
                                 SELECT lh.loan_id loan_id, max(lh.date) date
                                 FROM #{from}
                                 WHERE lh.status in (5,6,7,8)
                                 AND lh.date<='#{to_date.strftime('%Y-%m-%d')}' #{extra}
                                 GROUP BY lh.loan_id
                                 }).collect{|x| "(#{x.loan_id}, '#{x.date.strftime('%Y-%m-%d')}')"}.join(",")
    return false if ids.length==0
    
    if group_by.class==String
      group_by = group_by+"_id"
    elsif group_by.class==Array
      group_by = group_by.map{|x| x+"_id"}.join(", ")
    elsif group_by.class==Symbol
      group_by = "#{group_by}_id"
    else
      return
    end

    repository.adapter.query(%Q{
      SELECT 
        SUM(lh.scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(lh.scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(lh.actual_outstanding_principal)    AS actual_outstanding_principal,
        SUM(lh.actual_outstanding_total)        AS actual_outstanding_total,
        SUM(if(lh.actual_outstanding_principal<lh.scheduled_outstanding_principal, lh.scheduled_outstanding_principal-lh.actual_outstanding_principal,0)) AS advance_principal,
        SUM(if(lh.actual_outstanding_total<lh.scheduled_outstanding_total,         lh.scheduled_outstanding_total-lh.actual_outstanding_total,0))         AS advance_total,
        COUNT(lh.loan_id) loan_count,
        #{group_by}
      FROM loan_history lh, loans l
      WHERE (lh.loan_id, lh.date) in (#{ids}) AND lh.status in (5,6) AND lh.loan_id=l.id AND l.deleted_at is NULL
      GROUP BY #{group_by};
    })
  end

  # TODO: subsitute the body of this function with sum_outstanding_grouped_by
  def self.sum_outstanding_by_month(month, year, branch, loan_product_id=nil)
    date = Date.new(year, month, -1)
    extra, from = "", "loan_history lh"
    if loan_product_id and loan_product_id.to_i>0
      extra = "AND lh.loan_id=l.id AND l.loan_product_id=#{loan_product_id}"
      from += ", loans l"
    end
    ids=repository.adapter.query(%Q{
                                 SELECT lh.loan_id loan_id, max(lh.date) date
                                 FROM #{from}
                                 WHERE lh.branch_id=#{branch.id} AND lh.status in (5,6,7,8)
                                 AND lh.date<='#{date.strftime('%Y-%m-%d')}' #{extra}
                                 GROUP BY lh.loan_id
                                 }).collect{|x| "(#{x.loan_id}, '#{x.date.strftime('%Y-%m-%d')}')"}.join(",")
    return false if ids.length==0
    
    repository.adapter.query(%Q{
      SELECT 
        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(actual_outstanding_principal)    AS actual_outstanding_principal,
        SUM(actual_outstanding_total)        AS actual_outstanding_total,
        SUM(if(actual_outstanding_principal<scheduled_outstanding_principal,  scheduled_outstanding_principal-actual_outstanding_principal,0)) AS advance_principal,
        SUM(if(actual_outstanding_total<scheduled_outstanding_total,          scheduled_outstanding_total-actual_outstanding_total,0))         AS advance_total,
        branch_id
      FROM loan_history
      WHERE (loan_id, date) in (#{ids}) AND status in (5,6)
      GROUP BY branch_id;
    })
  end

  def self.sum_outstanding_for(obj, from_date=Date.today-7, to_date=Date.today)
    if [Branch, Center, ClientGroup].include?(obj.class)
      q = "#{obj.class.name.snake_case}_id"
      query = "#{q}=#{obj.id}"
    elsif obj.class==Region or obj.class==Area
      ids = (obj.class==Region ? obj.areas.branches(:fields => [:id]).map{|x| x.id} : obj.branches(:fields => [:id]).map{|x| x.id})
      ids = (ids.length==0 ? "NULL" : ids.join(","))
      query="branch_id in (#{ids})"
      q = "branch_id"
    elsif obj.class==StaffMember
      ids = Loan.all(:fields => [:id], :disbursed_by_staff_id => obj.id).map{|x| x.id}
      ids = (ids.length==0 ? "NULL" : ids.join(","))
      query="loan_id in (#{ids})"
      q = "branch_id"
    end

    ids=repository.adapter.query(%Q{
                                 SELECT lh.loan_id loan_id, max(lh.date) date
                                 FROM loan_history lh, loans l
                                 WHERE l.id=lh.loan_id AND l.deleted_at is NULL AND l.disbursal_date is NOT NULL
                                 AND #{query} AND lh.date>='#{from_date.strftime('%Y-%m-%d')}' 
                                 AND lh.date<='#{to_date.strftime('%Y-%m-%d')}'
                                 GROUP BY lh.loan_id
                                 }).collect{|x| "(#{x.loan_id}, '#{x.date.strftime('%Y-%m-%d')}')"}.join(",")
    return false if ids.length==0
    
    select  = %Q{
        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal,
        SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
        SUM(if(actual_outstanding_principal>0, actual_outstanding_principal,0))    AS actual_outstanding_principal,
        SUM(if(actual_outstanding_total>0,     actual_outstanding_total, 0))        AS actual_outstanding_total,
        SUM(if(actual_outstanding_principal<0, actual_outstanding_principal,0))    AS advance_principal,
        SUM(if(actual_outstanding_total<0,     actual_outstanding_total,0))        AS advacne_total,
        COUNT(DISTINCT(loan_id))             AS loans_count,
        COUNT(DISTINCT(client_id))           AS clients_count,
        branch_id
    }

    repository.adapter.query(%Q{
      SELECT #{select}
      FROM loan_history
      WHERE (loan_id, date) in (#{ids})
      GROUP BY #{q}
    })
  end

  def self.amount_disbursed_for(obj, from_date, to_date)
    select = "SELECT sum(l.amount) amount, COUNT(l.id) loan_count, COUNT(DISTINCT(l.client_id)) client_count"
    query = if obj.class==Branch
              %Q{
                 #{select}
                 FROM branches b, centers c, clients cl, loans l 
                 WHERE b.id=#{obj.id} and c.branch_id=b.id and cl.center_id=c.id and l.client_id=cl.id and l.disbursal_date is not null and l.deleted_at is null
                       and l.disbursal_date<='#{to_date.strftime('%Y-%m-%d')}' and l.disbursal_date>='#{from_date.strftime('%Y-%m-%d')}'
               }
            elsif obj.class==Center
              %Q{
                 #{select}
                 FROM   centers c, clients cl, loans l 
                 WHERE  c.id=#{obj.id} and cl.center_id=c.id and l.client_id=cl.id and l.disbursal_date is not null and l.deleted_at is null
                        and l.disbursal_date<='#{to_date.strftime('%Y-%m-%d')}' and l.disbursal_date>='#{from_date.strftime('%Y-%m-%d')}'
               }
            elsif obj.class==ClientGroup
              %Q{
                 #{select}
                 FROM   client_groups cg, clients cl, loans l 
                 WHERE  cg.id=#{obj.id} and cl.client_group_id=cg.id and l.client_id=cl.id and l.disbursal_date is not null and l.deleted_at is null
                        and l.disbursal_date<='#{to_date.strftime('%Y-%m-%d')}' and l.disbursal_date>='#{from_date.strftime('%Y-%m-%d')}'
               }
            elsif obj.class==Area
              %Q{
                 #{select}
                 FROM  regions r, areas a, branches b, centers c, clients cl, loans l 
                 WHERE a.id=#{obj.id} and a.id=b.area_id and c.branch_id=b.id and cl.center_id=c.id 
                       and l.client_id=cl.id and l.disbursal_date is not null and l.deleted_at is null
                       and l.disbursal_date<='#{to_date.strftime('%Y-%m-%d')}' and l.disbursal_date>='#{from_date.strftime('%Y-%m-%d')}'
               }
            elsif obj.class==Region
              %Q{
                 #{select}
                 FROM  regions r, areas a, branches b, centers c, clients cl, loans l 
                 WHERE r.id=#{obj.id} and r.id=a.region_id and a.id=b.area_id and c.branch_id=b.id and cl.center_id=c.id 
                       and l.client_id=cl.id and l.disbursal_date is not null and l.deleted_at is null
                       and l.disbursal_date<='#{to_date.strftime('%Y-%m-%d')}' and l.disbursal_date>='#{from_date.strftime('%Y-%m-%d')}'
               }
            elsif obj.class==StaffMember
              %Q{
                 #{select}
                 FROM  loans l 
                 WHERE l.disbursal_date is not null and l.deleted_at is null and l.disbursed_by_staff_id=#{obj.id} 
                       and l.disbursal_date<='#{to_date.strftime('%Y-%m-%d')}' and l.disbursal_date>='#{from_date.strftime('%Y-%m-%d')}'
               }
            end
    repository.adapter.query(query).first
  end

  def self.borrower_clients_count_in(obj)
    froms = ["clients cl", "loans l"]
    conditions = ["cl.id=l.client_id", "l.deleted_at is NULL"]

    klass = (obj.class == Array or obj.class==DataMapper::Associations::OneToMany::Collection) ? obj.first.class : obj.class
    obj   = (obj.class == Array or obj.class==DataMapper::Associations::OneToMany::Collection) ? obj : [obj]

    if klass==Branch
      froms << "centers c" 
      froms << "branches b"
      conditions << "b.id in (#{obj.map{|x| x.id}.join(',')})"
      conditions << "cl.center_id=c.id"
      conditions << "c.branch_id=b.id"
    elsif klass==Center
      froms << "centers c"
      conditions << "cl.center_id=c.id"
      conditions << "c.id in (#{obj.map{|x| x.id}.join(',')})"
    elsif klass==Area
      froms << "centers c"
      froms << "branches b"
      froms << "areas a"
      conditions << "a.id in (#{obj.map{|x| x.id}.join(',')})"
      conditions << "a.id=b.area_id"
      conditions << "c.branch_id=b.id"
      conditions << "cl.center_id=c.id"
    elsif klass==Region
      froms << "centers c"
      froms << "branches b"
      froms << "areas a"
      froms << "regions r"
      conditions << "r.id in (#{obj.map{|x| x.id}.join(',')})"
      conditions << "r.id=a.region_id"
      conditions << "a.id=b.area_id"
      conditions << "c.branch_id=b.id"
      conditions << "cl.center_id=c.id"
    end

    repository.adapter.query("SELECT count(*) FROM #{froms.join(', ')} WHERE #{conditions.join(' AND ')}")
  end
end
