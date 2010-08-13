class Dashboard < Application
  include Grapher
  PAYMENT_TYPES = {"principal" => 1, "interest" => 2, "fees" => 3}
  before :get_context
  before :display_from_cache, :exclude => [:index]
  after  :store_to_cache, :exclude => [:index]

  def index
    render
  end

  def today
    @date = params[:date].blank? ? Date.today : Date.parse(params[:date])
    render
  end

  def branch
    case params[:id]
    when "centers"
      if params[:quantity]=="count"
        graph = BarGraph.new("Centers count")
        vals = repository.adapter.query(%Q{SELECT COUNT(c.id) count, b.name name
                                           FROM centers c, branches b
                                           WHERE b.id=c.branch_id GROUP BY b.id;})
      elsif params[:quantity]=="staff_members"
        graph = BarGraph.new("Staff count")
        vals  = repository.adapter.query(%Q{
                                            SELECT COUNT(DISTINCT(c.manager_staff_id+b.manager_staff_id)) count, b.name name
                                            FROM centers c, branches b
                                            WHERE b.id=c.branch_id GROUP BY b.id;
                                           })
      elsif params[:quantity]=="clients_average"
        graph = BarGraph.new("Average number of clients per center")
        vals = repository.adapter.query(%Q{SELECT COUNT(cl.id)/COUNT(DISTINCT(c.id)) count, b.name name
                                           FROM clients cl, centers c, branches b
                                           WHERE cl.center_id=c.id AND b.id=c.branch_id GROUP BY b.id;})
      end
      graph.data_type = :individual
      graph.data(vals.map{|x| [x.count.to_i, x.name]}, :first, :last)
      return graph.generate      
    when "clients"
      if params[:quantity]=="count"
        graph = BarGraph.new("#{params[:id]} #{params[:quantity]}".capitalize)
        vals = repository.adapter.query(%Q{SELECT COUNT(cl.id) count, b.name name
                                           FROM clients cl, centers c, branches b
                                           WHERE cl.center_id=c.id AND b.id=c.branch_id GROUP BY b.id;})
      elsif params[:quantity]=="borrowers"
        graph = BarGraph.new("#{params[:quantity]} #{params[:id]}".capitalize)
        vals = repository.adapter.query(%Q{SELECT COUNT(DISTINCT(cl.id)) count, b.name name
                                           FROM clients cl, centers c, branches b, loans l
                                           WHERE l.disbursal_date is not NULL and cl.center_id=c.id AND cl.id=l.client_id AND b.id=c.branch_id GROUP BY b.id;})
      elsif params[:quantity]=="per_staff"
        graph = BarGraph.new("#{params[:id]} per staff member".capitalize)
        vals = repository.adapter.query(%Q{SELECT COUNT(DISTINCT(cl.id))/COUNT(DISTINCT(c.manager_staff_id)) count, b.name name
                                           FROM clients cl, centers c, branches b, loans l
                                           WHERE l.disbursal_date is not NULL and cl.center_id=c.id AND cl.id=l.client_id AND b.id=c.branch_id GROUP BY b.id;})
      end
      graph.data_type = :individual
      graph.data(vals.map{|x| [x.count.to_i, x.name]}, :first, :last)
      return graph.generate
    when "loan"
      column, reported = case params[:quantity]
                         when "avg"
                           ["#{params[:quantity]}(l.amount)", "Average loan amount disbursed"]
                         when "sum"
                           ["#{params[:quantity]}(l.amount)", "Loan amount disbursed"]
                         when "per_staff"
                           ["COUNT(l.id)/COUNT(DISTINCT(c.manager_staff_id))", "Loans per center manager"]
                         when "count"
                           ["#{params[:quantity]}(l.id)", "#{params[:id]} #{params[:quantity]}".capitalize]
                         end
      graph = BarGraph.new("#{reported.camelcase(' ')}")

      vals = repository.adapter.query(%Q{SELECT #{column} quantity, b.name name
                                       FROM loans l, clients cl, centers c, branches b
                                       WHERE l.disbursal_date is not NULL and l.client_id=cl.id AND cl.center_id=c.id AND b.id=c.branch_id 
                                       GROUP BY b.id;})
      graph.data_type = :individual
      graph.data(vals.map{|x| [x.quantity.to_i, x.name]})
      return graph.generate
    when "loan_history"
      graph = BarGraph.new("#{params[:report_type].split('_').join(' ').capitalize}")
      vals  = LoanHistory.sum_outstanding_grouped_by(Date.today, :branch)
      graph.data_type = :individual
      if params[:report_type]=="outstanding_principal" or params[:report_type]=="outstanding_total"
        graph.data(vals.map{|x| [x.send("actual_#{params[:report_type]}").to_i, Branch.get(x.branch_id).name]})
      elsif params[:report_type]=="average_outstanding_loan_amount_size"
        graph.data(vals.map{|x| [((x.actual_outstanding_principal||0)/x.loan_count).to_i, Branch.get(x.branch_id).name]})
      end
      return graph.generate
    else
      graph = BarGraph.new("Client growth at #{@branch.name}")
      vals  = repository.adapter.query(%Q{SELECT count(cl.id) count, cl.date_joined date 
                                          FROM clients cl, centers c 
                                          WHERE c.branch_id=#{@branch.id} and cl.center_id=c.id group by date(cl.date_joined)}).sort_by{|x| x.date}
      graph.data(vals)
      graph.x_axis.steps=5
      return graph.generate
    end
  end

  def centers
    growth_type = ((params[:id] and params[:id]=="growth") ? "Total" : "New")

    if @branch
      graph = BarGraph.new("#{growth_type} centers in #{@branch.name}")
      vals  = Center.all(:creation_date.not => nil, :branch => @branch, :creation_date.lte => Date.today).aggregate(:all.count, :creation_date)
    elsif @staff_member
      graph = BarGraph.new("#{growth_type} centers managed by #{@staff_member.name}")
      vals  = Center.all(:creation_date.not => nil, :manager => @staff_member, :creation_date.lte => Date.today).aggregate(:all.count, :creation_date)      
    else
      graph = BarGraph.new("#{growth_type} centers")
      vals  = Center.all(:creation_date.not => nil, :creation_date.lte => Date.today).aggregate(:all.count, :creation_date)
    end

    
    graph.title.text = graph.title.text + " (#{get_period_text})"
    graph.data_type  = (growth_type == "New" ? :individual : :cumulative)

    data    = vals.map{|c, d| {Date.new(d.year, d.month, 1) => c}}.inject({}){|s,x| s+=x}.to_a.sort_by{|d, c| d}
    data    = group_dates(data)
    graph.x_axis.steps=get_axis
    graph.data(data, :last, :first)
    return graph.generate
  end

  def clients
    case params[:id]
    when "growth", "cumulative"
      vals  = get_clients.all(:date_joined.lte => Date.today).aggregate(:all.count, :date_joined)
      data  = vals.map{|c, d| {Date.new(d.year, d.month, 1) => c}}.inject({}){|s,x| s+=x}.to_a
      if params[:id]=="growth"
        graph = BarGraph.new("Client cumulative growth (#{get_period_text})")
      else
        graph = BarGraph.new("Client growth #{get_period_text}")
        graph.data_type=:individual
      end
      data    = group_dates(data)
      graph.x_axis.steps=get_axis
      graph.data(data, :last, :first)
    when "breakup"
      graph  = PieGraph.new("Clients #{params[:group_by]} breakup")
      group_by = params[:group_by].to_sym
      graph.data(group_by_values(Client, get_clients, group_by, {:allow_blank => false}), :first, :last)
    when "profile"
      if params[:group_by]=="age"
        title = "Client age profile (in years)"
        year  = Date.today.year
        ages = get_clients.all(:date_of_birth.not => nil, :date_of_birth.lte => Date.today, :fields => [:id, :date_of_birth]).map{|cl| 
          year-cl.date_of_birth.year
        }.map{|x| (x/10)*10}
        data = ages.uniq.sort.map{|x| [ages.count(x), "#{x} - #{x+10}"]}
      else
        today = Date.today
        title = "Member since (in months)"
        ages  = get_clients.all(:date_joined.lte => Date.today, :fields => [:id, :date_joined]).map{|x| (today-x.date_joined).to_i/30}
        title = "Member since (in months/years)"
        data  = ages.find_all{|x| x<12}.map{|x| x/3}.group_by{|x| x}.map{|quarter, arr| [arr.length, "#{quarter*3+1} - #{quarter*3+3} months"]}
        years = ages.find_all{|x| x>=12}.map{|x| x/12}
        data += years.uniq.sort.map{|x| [years.count(x), "#{x} years"]}
      end
      
      graph  = BarGraph.new(title)
      graph.data_type = :individual
      group_by = params[:group_by].to_sym
      graph.data(data)
    end
    return graph.generate
  end

  def loans
    conditions = []
    conditions << " AND c.branch_id=#{params[:branch_id].to_i}"                  if params[:branch_id] and params[:branch_id].to_i > 0
    conditions << " AND l.disbursed_by_staff_id=#{params[:staff_member_id].to_i}" if params[:staff_member_id] and params[:staff_member_id].to_i > 0
    case params[:id]
    when "growth", "cumulative"
      vals = repository.adapter.query(%Q{
                                         SELECT count(cl.id) count, DATE(l.disbursal_date) date
                                         FROM clients cl, centers c, loans l 
                                         WHERE cl.center_id=c.id AND l.client_id=cl.id AND cl.deleted_at is NULL AND cl.date_joined<=CURRENT_DATE()
                                               AND l.disbursal_date is NOT NULL AND l.deleted_at is NULL #{conditions}
                                         GROUP BY l.disbursal_date
                                      }).map{|r| [r.date, r.count]}
      if params[:id]=="growth"
        graph = BarGraph.new("Number of borrowers added #{get_period_text}")
        graph.data_type = :individual
      else
        graph = BarGraph.new("Growth of number of borrowers (#{get_period_text})")
      end
      graph.data(group_dates(vals), :last, :first)
      graph.x_axis.steps = get_axis
      return graph.generate
    when "disbursements"
      vals = repository.adapter.query(%Q{
                                         SELECT SUM(l.amount) amount, DATE(l.disbursal_date) date
                                         FROM clients cl,centers c, loans l 
                                         WHERE cl.center_id=c.id AND l.client_id=cl.id AND cl.deleted_at is NULL AND cl.date_joined<=CURRENT_DATE()
                                               AND l.disbursal_date is NOT NULL AND l.deleted_at is NULL #{conditions}
                                         GROUP BY DATE(l.disbursal_date)
                                      }).map{|r| [r.date, r.amount.to_i]}
      graph = BarGraph.new("Amount disbursed (#{get_period_text})")
      graph.data_type = :individual
      graph.data(group_dates(vals), :last, :first)
      graph.x_axis.steps = get_axis
      return graph.generate
    when "outstanding"
      if params[:branch_id] and params[:branch_id].to_i > 0
        condition = "AND lh.branch_id=#{params[:branch_id]}"
        min_date  = Branch.get(params[:branch_id]).creation_date
      else
        min_date  = Loan.min(:disbursal_date)
      end
      data = []
      (min_date.year..Date.today.year).each{|year|
        1.upto(12){|month|
          date = Date.new(year, month, -1)
          next if date < min_date
          next if date > Date.today
          outstanding = repository.adapter.query(%Q{
                                     SELECT sum(outstanding) outstanding 
                                     FROM (SELECT min(actual_outstanding_principal) outstanding, max(date) date, loan_id, status 
                                           FROM loan_history lh, loans l 
                                           WHERE lh.loan_id=l.id AND l.deleted_at is NULL AND l.disbursal_date is NOT NULL AND lh.status in (5,6,7,8)
                                                 AND lh.date<='#{date.strftime('%Y-%m-%d')}' #{condition} GROUP BY loan_id) as ts WHERE ts.status in (5,6)
                                  })[0].to_i
          next if outstanding==0
          data << [date, outstanding]
        }
      }

      graph = BarGraph.new("Amount outstanding (#{get_period_text})")
      graph.data_type = :individual
      graph.data(group_dates(data), :last, :first)
      graph.x_axis.steps = get_axis
      return graph.generate      
    when "breakup"
      graph  = BarGraph.new("Loan breakup by #{params[:by].camelcase(' ')}")
      by     = params[:by].to_sym
      master = Kernel.const_get(params[:by].camelcase('')).all.map{|x| [x.id, x.name]}.to_hash
      return false unless by==:loan_product or by==:occupation
      by_col = "#{params[:by]}_id"
      data   = repository.adapter.query(%Q{
                                         SELECT COUNT(l.id) count, l.#{by_col} col
                                         FROM clients cl,centers c, loans l
                                         WHERE cl.center_id=c.id AND l.client_id=cl.id AND cl.deleted_at is NULL AND cl.date_joined<=CURRENT_DATE()
                                               AND l.disbursal_date is NOT NULL AND l.deleted_at is NULL #{conditions}
                                         GROUP BY l.#{by_col}
                                      }).map{|r| 
        [r.count, (master.key?(r.col.to_i) ? master[r.col.to_i] : "NA")]
      }
      #group_by_values(Loan, Loan.all, by, {:allow_blank => true})
      data   = data.sort_by{|c, o| c}.reverse
      graph.data_type = :individual
      graph.data(data, :first, :last)
      return graph.generate
    when "aging"
      ages = {1 => 0, 2 => 0, 3 => 0, 4  => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0}
      Loan.all(:disbursal_date.not => nil, :disbursal_date.lte => Date.today).each{|l|
        age = (100*(Date.today-l.disbursal_date)/(l.number_of_installments * l.installment_frequency_in_days)/10).ceil
        next if age>10
        next unless ages[age]
        ages[age]+=1
      }
      vals = []
      ages.to_a.sort_by{|x| x[0]}.each{|key, count|
        vals.push([count, "#{(key-1)*10} to #{key*10} %"])
      }      
      graph = BarGraph.new("Aging analysis")
      graph.data_type=:individual
      graph.data(vals)
      return graph.generate      
    when "yield"
      graph = BarGraph.new("Yield on portfolio")
      vals  = LoanHistory.sum_outstanding_grouped_by(Date.today, :branch)
      graph.data_type = :individual
      graph.data(vals.map{|x| 
                   branch=Branch.get(x.branch_id)
                   [
                    100 * (Payment.collected_for(branch,Date.min_date,Date.max_date,[2,3]).values.inject(0){|s,a| s+=a}).round(2)/(x.actual_outstanding_principal||0).to_f,
                    branch.name
                   ]
                 })
      return graph.generate
    when "portfolio_at_risk"
      graph = BarGraph.new("Portfolio at risk")
      vals  = LoanHistory.sum_outstanding_grouped_by(Date.today, :branch)
      graph.data_type = :individual
      graph.data(vals.map{|x|
                   branch=Branch.get(x.branch_id)
                   principal_overdue = if history = LoanHistory.defaulted_loan_info_for(branch)
                                         history.principal_due
                                       else
                                         0
                                       end
                   [(100*(principal_overdue/(x.actual_outstanding_principal||0)).to_f).round(2), branch.name]
                 })
      return graph.generate
    end
  end

  def payments
    conditions = []
    conditions << " AND branch_id=#{params[:branch_id].to_i}"                  if params[:branch_id] and params[:branch_id].to_i > 0
    conditions << " AND received_by_staff_id=#{params[:staff_member_id].to_i}" if params[:staff_member_id] and params[:staff_member_id].to_i > 0

    case params[:id]
    when "principal", "interest", "fees", "total"
      types = PAYMENT_TYPES.key?(params[:id]) ? [PAYMENT_TYPES[params[:id]]] : PAYMENT_TYPES.values
      vals = repository.adapter.query(%Q{
                                         SELECT SUM(p.amount) amount, DATE(p.received_on) date
                                         FROM payments p, clients cl, centers c
                                         WHERE p.deleted_at is null AND p.type in (#{types.join(', ')}) AND p.client_id = cl.id AND cl.center_id = c.id #{conditions}
                                         GROUP BY MONTH(p.received_on)
                                      }).map{|r| [r.date, r.amount.to_i]}
      graph = BarGraph.new("Repayment of #{params[:id]} (#{get_period_text})")
      graph.data_type = :individual
      graph.data(group_dates(vals), :last, :first)
      graph.x_axis.steps = get_axis
      return graph.generate
    when "amounts"
      vals = repository.adapter.query(%Q{
                                         SELECT amount, count(*) count 
                                         FROM (
                                               SELECT SUM(amount) amount, received_on, count(*) count
                                               FROM payments p, clients cl, centers c
                                               WHERE p.deleted_at is null AND p.amount>0 AND p.client_id=cl.id AND cl.center_id=c.id #{conditions} 
                                               GROUP BY p.received_on, p.client_id) as ts 
                                         GROUP BY amount ORDER BY count DESC LIMIT 10
                                      }).map{|r| [r.count, r.amount.to_i]}
      
      graph = BarGraph.new("Repayment denominations")
      graph.data_type = :individual
      graph.data(vals, :first, :last)
      graph.x_axis.steps = get_axis
      return graph.generate      
    end
  end

  private
  def group_by_values(model, collection, group_by, opts = {})
    opts[:allow_blank]=false if not opts.key?(:allow_blank)
    property = model.properties.find{|x| x.name==group_by} 

    if property and property.type.class==Class
      lookup = property.type.flag_map
    elsif property
      lookup = false
    elsif model.relationships.key?(group_by)
      lookup = {}
      model.relationships[group_by].parent_model.all.each{|x| lookup[x.id]=x.name}
      group_by = model.relationships[group_by].child_key.first.name
    end

    if lookup
      lookup[""]  = lookup[nil] = "Not specified" if opts[:allow_blank]
      return [] if collection.count == 0
      return collection.aggregate(:all.count, group_by).map{|c|
        id = c[1].to_i
        [c[0], lookup[id]]
      }.reject{|x| x[1].nil? or x[1].blank?}
    else
      if opts[:allow_blank]
        return collection.aggregate(:all.count, group_by)
      else
        return collection.aggregate(:all.count, group_by).reject{|x| x.nil? or x.blank?}
      end
    end
  end

  def display_from_cache
    return false if params[:action]=="dashboard" and params[:id]=="center_day"
    file = get_cached_filename
    return true unless File.exists?(file)
    return true if not File.mtime(file).to_date==Date.today
    throw :halt, render(File.read(file), :layout => false)
  end
  
  def store_to_cache
    return false if params[:action]=="dashboard" and params[:id]=="center_day"
    file = get_cached_filename
    if not (File.exists?(file) and File.mtime(file).to_date==Date.today)
      File.open(file, "w"){|f|
        f.puts @body
      }
    end
  end
  
  def get_cached_filename
    hash = params.deep_clone
    controller = hash.delete(:controller).to_s
    action     = hash.delete(:action).to_s
    [:format, :submit].each{|x| hash.delete(x)}
    dir = File.join(Merb.root, "public", controller, action)
    unless File.exists?(dir)
      FileUtils.mkdir_p(dir)
    end
    File.join(dir, hash.collect{|k,v| "#{k}_#{v}"}.join("_"))
  end
  
  def get_steps(max)
    divisor = power(max)
    (max/(10**divisor)).to_i*10*divisor
  end
  
  def power(val, base=10)
    itr=1
    while val/(base**itr) > 1
      itr+=1
    end
    return itr-1
  end

  def get_clients
    hash = {}
    [:branch_id, :center_id, :staff_member_id].each{|attr| hash[attr] = params[attr] if params[attr] and not params[attr].blank?}
    if hash.empty?
      return Client
    else
      if hash[:center_id]
        hash.delete(:branch_id)
        Client.all(hash)
      elsif hash[:staff_member_id]
        StaffMember.get(hash[:staff_member_id]).clients
      elsif hash[:branch_id]
        Center.all(hash).clients(:fields => [:id, :date_joined, :religion, :caste])
      else
        Client
      end
    end
  end

  def get_context
    @branch = Branch.get(params[:branch_id]) if params[:branch_id] and not params[:branch_id].nil? and /\d+/.match(params[:branch_id])
    @center = Center.get(params[:center_id]) if params[:center_id] and not params[:center_id].nil?
    @staff_member = StaffMember.get(params[:staff_member_id]) if params[:staff_member_id] and not params[:staff_member_id].nil?
  end

  def quarter(date)
    if date.month<=3
      return "#{date.year-1}-#{date.year} Q4"
    elsif date.month>3 and date.month<7
      return "#{date.year}-#{date.year+1} Q1"
    elsif date.month>=7 and date.month<=9
      return "#{date.year}-#{date.year+1} Q2"
    elsif date.month>=10 and date.month<=12
      return "#{date.year}-#{date.year+1} Q3"
    end
  end

  # accounting year
  def year(date)
    if date.month<=3
      return "#{date.year-1}-#{date.year}"
    else
      return "#{date.year}-#{date.year+1}"
    end
  end

  def group_dates(data)
    if not params[:time_period] or params[:time_period]=="monthly"
      return data.group_by{|d, c| Date.new(d.year, d.month, 1)}.map{|k, v| [k, v.map{|x| x[1]}.inject(0){|s,x| s+=x}]}.sort_by{|d, c| d}.map{|k, v| [k.strftime("%Y %b"), v]}
    elsif params[:time_period]=="quarterly"
      return data.group_by{|d, c| quarter(d)}.map{|k, v| [k, v.map{|x| x[1]}.inject(0){|s,x| s+=x}]}.sort_by{|d, c| d}
    elsif params[:time_period]=="yearly"
      return data.group_by{|d, c| year(d)}.map{|d, c| [d, c.map{|d, c| c}.inject(0){|s, x| s+=x}]}.sort_by{|d, c| d}
    end
  end

  def get_axis
    if not params[:time_period] or params[:time_period]=="monthly"
      return 3
    elsif params[:time_period]=="quarterly"
      return 2
    elsif params[:time_period]=="yearly"
      return 1
    end    
  end

  def get_period_text
    if not params[:time_period] or params[:time_period]=="monthly"
      "month on month"
    elsif params[:time_period]=="quarterly"
      "quarter on quarter"
    elsif params[:time_period]=="yearly"
      "year on year"
    end    
  end

end


