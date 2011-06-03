class Report
  include DataMapper::Resource

  attr_accessor :raw
  property :id, Serial
  property :start_date, Date
  property :end_date, Date
  property :report, Yaml, :length => 20000
  property :dirty, Boolean
  property :report_type, Discriminator
  property :created_at, DateTime
  property :generation_time, Integer

  validates_with_method :method => :from_date_should_be_less_than_to_date

  def name
    "#{report_type}: #{start_date} - #{end_date}"
  end

  def get_parameters(params, user=nil)
    staff     = user.staff_member if user
    @funder = Funder.first(:user_id => user.id) if user and user.role == :funder
    @branch = get_branches(params, staff)
    @account = Account.all(:order => [:name])

    # if an area is selected then filter branches against their managed areas > branches list
    # if the user is a funder then get related areas
    if @area = get_areas(params)
      if user and staff
        @area = @area & [staff.branches.areas, staff.areas].flatten
      elsif @funder
        @area = @area & @funder.areas
      end
      @branch = Branch.all(:area_id => @area.map{|a| a.id})
    end

    set_centers(params, user, staff)
    @funder = Funder.get(params[:funder_id]) if not @funder and params and params[:funder_id] and not params[:funder_id].blank?

    [:loan_product_id, :late_by_more_than_days, :more_than, :late_by_less_tehan_days, :attendance_status, :include_past_data, :include_unapproved_loans].each{|key|
      if params and params[key] and params[key].to_i>0
        instance_variable_set("@#{key}", params[key].to_i)
      end
    }
    set_instance_variables(params)
  end

  def calc
    t0 = Time.now
    all(:report_type => self.report_type, :start_date => self.start_date, :end_date => self.end_date).destroy!
    self.report = Marshal.dump(self.generate)
    self.generation_time = Time.now - t0
    self.save
  end

  def group_loans(by, columns, conditions = {})
    by_query = if by.class == String
                 by
               elsif by.class==Symbol
                 "l.#{by}"
               elsif by.class==Array
                 by.join(",")
               end
    condition, select = process_conditions(conditions)
    repository.adapter.query(%Q{
       SELECT #{[by, columns, select].flatten.reject{|x| x.blank?}.join(', ')}
       FROM branches b, centers c, clients cl, loans l
       WHERE b.id=c.branch_id AND c.id=cl.center_id AND cl.id=l.client_id AND l.deleted_at is NULL AND cl.deleted_at is NULL AND l.rejected_on is NULL
             #{condition}
       GROUP BY #{by_query}
    })    
  end

  def get_pdf
    pdf = PDF::HTMLDoc.new
    pdf.set_option :bodycolor, :white
    pdf.set_option :toc, false
    pdf.set_option :portrait, true
    pdf.set_option :links, true
    pdf.set_option :webpage, true
    pdf.set_option :left, '2cm'
    pdf.set_option :right, '2cm'
    pdf.set_option :header, "Header here!"
    f = File.read("app/views/reports/_#{name.snake_case.gsub(" ","_")}.pdf.haml")
    report = Haml::Engine.new(f).render(Object.new, :report => self)
    pdf << report
    pdf.footer ".t."
    pdf
  end

  def get_xls
    f   = File.read("app/views/reports/_#{self.class.to_s.snake_case.gsub(' ', '_')}.html.haml").gsub("=partial :form\n", "")
    doc = Hpricot(Haml::Engine.new(f).render(Object.new, "@data" => self.generate))
    headers = doc.search("tr.header").map{|tr|
      tr.search("th").map{|td|
        [td.inner_text.strip => td.attributes["colspan"].blank? ? 1 : td.attributes["colspan"].to_i]
      }
    }.map{|x| 
      x.reduce([]){|s,x| s+=x}
    }
    
  end

  def process_conditions(conditions)
    selects = []
    conditions = conditions.map{|query, value|
      key      = get_key(query)
      operator = get_operator(query, value)
      value    = get_value(value)
      operator = " is " if value == "NULL" and operator == "="
      next if not key
      "#{key}#{operator}#{value}"
    }
    query = ""
    query = " AND " + conditions.join(' AND ') if conditions.length>0
    [query, selects.join(', ')]
  end

  def get_key(query)
    if query.class==DataMapper::Query::Operator
      return query.target
    elsif query.class==String
      return query
    elsif query.class==Symbol and query==:fields
      return nil
    else
      return query
    end    
  end
  
  def get_operator(query, value)
    if query.respond_to?(:operator)
      case query.operator
      when :lte
        "<="
      when :gte
        ">="
      when :gt
        ">"
      when :lt
        "<"
      when :eq
        "="
      when :not
        " is not "
      else
        "="
      end
    elsif value.class == Array
      " in "
    else
      "="
    end
  end

  def get_value(val)
    if val.class==Date
      "'#{val.strftime("%Y-%m-%d")}'"
    elsif val.class==Array
      "(#{val.join(",")})"
    elsif val.nil?
      "NULL"
    else
      val
    end    
  end

  def date_should_not_be_in_future
    return [false, "Date cannot be in futute"] if self.respond_to?(:date) and self.date > Date.today
    return [false, "From date cannot be in futute"] if self.respond_to?(:from_date) and self.from_date > Date.today
    return [false, "To date cannot be in futute"] if self.respond_to?(:to_date) and self.to_date > Date.today
    return true
  end

  def branch_should_be_selected
    return [false, "Branch needs to be selected"] if self.respond_to?(:branch_id) and not self.branch_id
    return true
  end

  private
  def get_branches(params, staff)
    # if a branch is selected pick that or pick all of them
    if staff
      staff.related_branches
    elsif (params and params[:branch_id] and not params[:branch_id].blank?)
      Branch.all(:id => params[:branch_id])
    else
      Branch.all(:order => [:name])
    end
  end

  def get_areas(params)
    #if an area is selected pick otherwise pick NONE of them
    if (params and params[:area_id] and not params[:area_id].blank?)
      Area.all(:id => params[:area_id])
    end
  end

  def set_centers(params, user=nil, staff=nil)
    params||={}

    # if a center is selected pick that
    if params and params[:center_id] and not params[:center_id].blank?
      @center = Center.all(:id => params[:center_id])
    end

    # if the user is a staff member or funder and center is not selected then pick all the managed centers
    @center = 
      if user and not @center and (not params[:staff_member_id] or params[:staff_member_id].blank?)
        if staff and (not params[:staff_member_id] or params[:staff_member_id].blank?)
          # if user is a staff and not staff member is selected then fill eligible staff members          
          staff.related_centers
        elsif staff and params[:staff_member_id] and not params[:staff_member_id].blank?
          # if user is a staff and staff member is selected then fill eligible centers of staff member
          staff.related_centers & StaffMember.get(params[:staff_member_id]).centers
        elsif @funder and (not params or not params[:staff_member_id] or params[:staff_member_id].blank?)
          # if funder is selected and no staff is selected
          @funder.centers
        elsif @funder and params[:staff_member_id] and not params[:staff_member_id].blank?
          @funder.centers & StaffMember.get(params[:staff_member_id]).centers
        end
      elsif @center and params and params[:staff_member_id] and not params[:staff_member_id].blank?
        @center & StaffMember.get(params[:staff_member_id]).centers
      elsif params and params[:staff_member_id] and not params[:staff_member_id].blank?
        StaffMember.get(params[:staff_member_id]).centers
      else
        @center
      end
    @center = @branch.centers if not @center
  end

  def set_instance_variables(params)
    params.each{|key, value|
      instance_variable_set("@#{key}", value.to_i) if not [:date, :from_date, :to_date].include?(key.to_sym) and value and value.to_i>0
    } if params
  end

  def from_date_should_be_less_than_to_date
    if @from_date and @to_date and @from_date > @to_date
      return [false, "From date should be before to date"]
    end
    return true
  end

  def get_extra
    extra     = []
    extra    << "l.loan_product_id = #{self.loan_product_id}" if loan_product_id

    if @branch.length > 0 and @branch.length != Branch.count
      extra    << "lh.branch_id in (#{@branch.map{|b| b.id}.join(', ')})"
    end

    if @center and @center.length > 0 and @center.length != Center.count
      extra    << "lh.center_id in (#{@center.map{|c| c.id}.join(', ')})"
    end

    if @report_by_loan_disbursed == 1 
      extra    << "l.disbursal_date >='#{from_date.strftime('%Y-%m-%d')}' and l.disbursal_date <='#{to_date.strftime('%Y-%m-%d')}'"
    end

    # if a funder is selected
    if @funder
      funder_loan_ids = @funder.loan_ids
      funder_loan_ids = ["NULL"] if funder_loan_ids.length == 0
      extra    << "l.id in (#{funder_loan_ids.join(", ")})" 
    end

    #if funding_lines are selected
    if @funding_line
      funding_line_ids = @funding_line.funder
      funding_line_ids = ["NULL"] if funding_line_ids.length == 0
      extra   << "l.id in (#{funding_line_ids.join(", ")})"
    end
    
    #if loan cycle_number is selected
    if @loan_cycle
      lc = @loan_cycle
      lc = ["NULL"] if @loan_cycle.nil?
      extra   << "l.cycle_number = #{lc}"
    end
    [extra, funder_loan_ids]
  end

  def get_payment_extra_and_froms(centers, funder_loan_ids)
    extra_condition = ""
    froms = ["payments p", "clients cl", "centers c"]

    if self.branch_id
      center_ids  = centers.keys.length>0 ? centers.keys.join(',') : "NULL"
      extra_condition += "AND c.id in (#{center_ids})"
    end

    if self.loan_product_id
      froms << "loans l"
      extra_condition += " and p.loan_id=l.id and l.loan_product_id=#{self.loan_product_id}"
    end

    if report_by_loan_disbursed and report_by_loan_disbursed == 1
      froms << "loans l"
      extra_condition += " and p.loan_id=l.id and l.disbursal_date >='#{from_date.strftime('%Y-%m-%d')}' and l.disbursal_date <='#{to_date.strftime('%Y-%m-%d')}'"
    end
    
    if @funder
      froms << "loans l"
      extra_condition += "and p.loan_id=l.id" unless extra_condition.include?("and p.loan_id=l.id")
      extra_condition += " and l.id in (#{funder_loan_ids.join(', ')})"
    end

    if @funding_line
      froms << "loans l"
      extra_condition += "and p.loan_id=l.id" unless extra_condition.include?("and p.loan_id=l.id")
      extra_condition += "and l.id in (#{funding_line_ids.join(', ')})"
    end

    if @loan_cycle
      lc = @loan_cycle
      lc = ["NULL"] if @loan_cycle.nil?

      froms << "loans l"
      extra_condition += "and p.loan_id=l.id" unless extra_condition.include?("and p.loan_id=l.id")
      extra_condition += "and l.cycle_number = #{lc}"
    end
    [froms.uniq.join(", "), extra_condition]
  end

  # This function adds corresponding rows of 'obj' in histories, advances, balances etc 
  # to data hash at key obj.
  def add_outstanding_to(data, obj, histories, advances, balances, old_balances, defaults)
    #0              1                 2                3              4              5     6                  7         8    9,10,11     12       
    #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults
    history  = histories[obj.id][0]       if histories.key?(obj.id)
    advance  = advances[obj.id][0]        if advances.key?(obj.id)
    balance  = balances[obj.id][0]        if balances.key?(obj.id)
    old_balance = old_balances[obj.id][0] if old_balances.key?(obj.id)
    
    if history
      principal_scheduled = history.scheduled_outstanding_principal
      total_scheduled     = history.scheduled_outstanding_total
      
      principal_actual    = history.actual_outstanding_principal
      total_actual        = history.actual_outstanding_total
    else
      return
    end

    add_to_result(data, obj, 7, principal_actual)
    add_to_result(data, obj, 9, total_actual)
    add_to_result(data, obj, 8, total_actual - principal_actual)

    #overdue
    if defaults[obj.id]
      add_to_result(data, obj, 10, defaults[obj.id].pdiff)
      add_to_result(data, obj, 12, defaults[obj.id].tdiff)
      add_to_result(data, obj, 11, defaults[obj.id].tdiff - defaults[obj.id].pdiff)
    end
    
    new_advance         = advance ? advance.advance_total : 0
    new_advance_balance = balance ? balance.balance_total : 0
    old_advance_balance = old_balance ? old_balance.balance_total : 0
    #advance
    add_to_result(data, obj, 13, new_advance)
    add_to_result(data, obj, 14, new_advance + old_advance_balance - new_advance_balance )
    add_to_result(data, obj, 15, new_advance_balance)
    data
  end 

  def add_payments_to(data, obj, payment)
    if payment.ptype==1
      add_to_result(data, obj, 3, payment.amount.round(2))
    elsif payment.ptype==2
      add_to_result(data, obj, 4, payment.amount.round(2))
    elsif payment.ptype==3
      add_to_result(data, obj, 5, payment.amount.round(2))
     end
    data[obj][6] = data[obj][3] + data[obj][4] + data[obj][5]
    data
  end


  def add_to_result(data, obj, column, value)
    data[obj] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    data[obj][column] ||= 0
    data[obj][column] += value
  end

end
