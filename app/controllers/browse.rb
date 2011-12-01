class Browse < Application
  provides :xml 
  before :get_centers_and_template
  Line = Struct.new(:ip, :date_time, :method, :model, :url, :status, :response_time)
  
  def index
    render
  end

  def today
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @caches = BranchCache.all(:date => @date)
    @branch_data = @caches.map{|c| [c.model_id, c]}.to_hash
    @branch_names = Branch.all.aggregate(:name, :id).to_hash
    display [@branch_data, @branch_names], @template
  end


  def branches
    redirect resource(:branches)
  end

  def centers
    if session.user.role == :staff_member
      @centers = Center.all(:manager => session.user.staff_member, :order => [:meeting_day]).paginate(:per_page => 15, :page => params[:page] || 1)
    else
      @centers = Center.all.paginate(:per_page => 15, :page => params[:page] || 1)
    end
    @branch =  @centers.branch[0]
    render :template => 'centers/index'
  end

  def hq_tab
    partial :totalinfo rescue partial :missing_caches
  end

  def centers_paying_today
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    hash  = {:date => @date, :status.not => [:rejected]}
    hash += {:branch_id => params[:branch_id]} if params[:branch_id] and not params[:branch_id].blank?
    center_ids = LoanHistory.all(hash).aggregate(:center_id)
    loans      = LoanHistory.all(hash).aggregate(:loan_id, :center_id).to_hash

    # restrict branch manager and center managers to their own branches
    if user = session.user and staff = user.staff_member
      hash[:branch_id] = [staff.related_branches.map{|x| x.id}, staff.centers.branches.map{|x| x.id}].uniq
      center_ids = staff.related_centers.map{|x| x.id} & center_ids
    end
    
    if Mfi.first.map_enabled
      @locations = Location.all(:parent_id => center_ids, :parent_type => "center").group_by{|x| x.parent_id}
    end

    @fees_due, @fees_paid, @fees_overdue  = Hash.new(0), Hash.new(0), Hash.new(0)
    unless loans.empty?
      Fee.due(loans.keys, {:date => @date}).each{|lid, fa|
        @fees_due[loans[lid]] += fa.due
      }
    end

    Payment.all(:type => :fees, :received_on => @date, "client.center_id" => center_ids).aggregate(:loan_id, :amount.sum).each{|fp|
      @fees_paid[loans[fp[0]]] += fp[1]
    } if center_ids.length>0

    @disbursals = {}
    @disbursals[:scheduled] = LoanHistory.all("loan.scheduled_disbursal_date" => @date, :date => @date).aggregate(:center_id, :scheduled_outstanding_principal.sum).to_hash
    
    @disbursals[:actual]    = LoanHistory.all("loan.scheduled_disbursal_date" => @date, :date => @date, 
                                              :status => [:disbursed]).aggregate(:center_id, :scheduled_outstanding_principal.sum).to_hash

    # caclulating old outstanding for loans, paying today, as of last payment date
    old_outstanding = {}
    LoanHistory.sum_outstanding_grouped_by(@date - 1, [:loan], {:center_id => center_ids}).group_by{|x| old_outstanding[x.loan_id] = x}

    # calculating outstanding for loans, paying today, as of today
    new_outstanding = LoanHistory.sum_outstanding_grouped_by(@date, [:loan], {:center_id => center_ids}, [:branch, :center, :principal_due, 
                                                                                                          :interest_due, :principal_paid, :interest_paid]).group_by{|x| 
      x.branch_id
    }.map{|branch_id, centers|
      {branch_id => centers.group_by{|loan| loan.center_id}}
    }.reduce({}){|s,x| s+=x}

    @centers  = Center.all(:id => center_ids)
    @branches = @centers.branches.map{|b| [b.id, b.name]}.to_hash
    @centers  = @centers.map{|c| [c.id, c]}.to_hash

    #get payments done on @date in format of {<loan_id> => [<principal>, <interest>]}
    @payments = {}
    @payments = LoanHistory.all(:date => @date, :center_id => center_ids).aggregate(:loan_id, :principal_paid.sum, :interest_paid.sum).group_by{|x| 
      x[0]
    } if center_ids.length > 0

    #advance balance
    new_advance_balances = LoanHistory.advance_balance(@date, [:center],   {:center_id => center_ids}).group_by{|x| x.center_id}
    old_advance_balances = LoanHistory.advance_balance(@date - 1, [:center], {:center_id => center_ids}).group_by{|x| x.center_id}

    # fill out @data with {branch => {center => row}}
    @data = {}
    new_outstanding.each{|branch_id, centers|
      @data[branch_id] ||= {}
      centers.each{|center_id, loans|        
        @data[branch_id][center_id] ||= Array.new(11, 0)
        
        loans.each{|loan|
          if old_outstanding.key?(loan.loan_id)
            # scheduled due
            @data[branch_id][center_id][2] += old_outstanding[loan.loan_id].actual_outstanding_principal - loan.scheduled_outstanding_principal
            @data[branch_id][center_id][3] += old_outstanding[loan.loan_id].actual_outstanding_total - old_outstanding[loan.loan_id].actual_outstanding_principal - loan.scheduled_outstanding_total + loan.scheduled_outstanding_principal

            #payments
            if @payments.key?(loan.loan_id)
              @data[branch_id][center_id][4] += @payments[loan.loan_id][0][1]
              @data[branch_id][center_id][5] += @payments[loan.loan_id][0][2]
            end

            # overdue
            @data[branch_id][center_id][6] += loan.actual_outstanding_principal - loan.scheduled_outstanding_principal if loan.actual_outstanding_principal > loan.scheduled_outstanding_principal
            @data[branch_id][center_id][7] += loan.actual_outstanding_total     - loan.scheduled_outstanding_total if loan.actual_outstanding_total > loan.scheduled_outstanding_total 

            #advance collected
            @data[branch_id][center_id][8] += (-1 * loan.principal_due) if loan.principal_due < 0 and loan.principal_paid > 0
            @data[branch_id][center_id][8] += (-1 * loan.interest_due) if loan.interest_due < 0 and loan.interest_paid > 0
          end
        }

        collected  = @data[branch_id][center_id][8]

        #advance balance
        new_balance = 0
        new_balance = new_advance_balances[center_id][0].balance_total if new_advance_balances[center_id]
        @data[branch_id][center_id][10]  += new_balance
        
        # adjusted
        old_balance = old_advance_balances[center_id] ? old_advance_balances[center_id][0].balance_total : 0
        @data[branch_id][center_id][9] += old_balance + collected - new_balance

      }
    }
      render :template => 'dashboard/today'
  end

  # method to parse log file and show activity. 
  def show_log
    @@models ||=  DataMapper::Model.descendants.map{|d| [d.to_s.snake_case.pluralize, d]}.to_hash
    @@not_reported_controllers ||= ["merb_auth_slice_password/sessions", "exceptions", "entrance", "login", "searches"]
    @lines = []
    ignore_regex = /\/images|\/javascripts|\/stylesheets|\/open-flash-chart|\/searches|\/dashboard|\/graph_data|\/browse/
    `tail -500 log/#{Merb.env}.log`.split(/\n/).reverse.each{|line|
      next if ignore_regex.match(line)
      ip, date_time, timezone, method, uri, http_type, status, size, response_time  = line.strip.gsub(/(\s\-\s)|\[|\]|\"/, "").split(/\s/).reject{|x| x==""}
      uri = URI.parse(uri)
      method = method.to_s.upcase || "GET"
      request = Merb::Request.new(
                                  Merb::Const::REQUEST_PATH => uri.path,
                                  Merb::Const::REQUEST_METHOD => method,
                                  Merb::Const::QUERY_STRING => uri.query ? CGI.unescape(uri.query) : "")
      route = Merb::Router.match(request)[1] rescue nil
      route.merge!(uri.query.split("&").map{|x| x.split("=")}.to_hash) if uri.query

      next if not route[:controller] or @@not_reported_controllers.include?(route[:controller])
      model = @@models[route[:controller]] if @@models.key?(route[:controller])
      @lines.push(Line.new(ip, date_time, method.downcase.to_sym, model, route, status.to_i, response_time.split(/\//)[0]))
    }
    render
  end

  private
  def get_centers_and_template
    if session.user.staff_member
      @staff ||= session.user.staff_member
      if branch = Branch.all(:manager => @staff)
        true
      else
        @centers = Center.all(:manager => @staff)
        @template = 'browse/for_staff_member'
      end
    end
  end

end
