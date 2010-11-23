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

  def name
    "#{report_type}: #{start_date} - #{end_date}"
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

  def get_parameters(params, user=nil)
    st     = user.staff_member if user
    @funder = Funder.first(:user_id => user.id) if user and user.role == :funder

    # if a branch is selected pick that or pick all of them
    @branch = if (params and params[:branch_id] and not params[:branch_id].blank?)
                Branch.all(:id => params[:branch_id])
              else
                Branch.all(:order => [:name])
              end
    
    # if the user is staff member or a funder then filter the branches against their managed branches list
    if user and st
      @branch = @branch & [st.centers.branches, st.branches].flatten
    elsif @funder
      @branch = @branch & @funder.branches
    end

    # if a center is selected pick that
    @center = Center.all(:id => params[:center_id]) if params and params[:center_id] and not params[:center_id].blank?

    # if the user is a staff member or funder and center is not selected then pick all the managed centers
    @center = if user and not @center and (params and (not params[:staff_member_id] or params[:staff_member_id].blank?))
                if st and (not params or not params[:staff_member_id] or params[:staff_member_id].blank?)
                  [st.centers, st.branches.centers].flatten
                elsif st and params[:staff_member_id] and not params[:staff_member_id].blank?
                  StaffMember.get(params[:staff_member_id]).centers
                elsif @funder and (not params or not params[:staff_member_id] or params[:staff_member_id].blank?)
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
    @center = @branch.collect{|b| b.centers}.flatten unless @center

    
    @funder = Funder.get(params[:funder_id]) if not @funder and params and params[:funder_id] and not params[:funder_id].blank?
    @loan_product_id = if params and params[:loan_product_id] and params[:loan_product_id].to_i>0
                      params[:loan_product_id].to_i
                    else
                      nil
                    end

    [:late_by_more_than_days, :absent_more_than].each{|key|
      instance_variable_set("@#{key}", if params and params[key] and params[key].to_i>0
                                         params[key].to_i
                                       else
                                         nil
                                       end)
    }
    [:late_by_less_than_days, :absent_more_than].each{|key|
      instance_variable_set("@#{key}", if params and params[key] and params[key].to_i>0
                                         params[key].to_i
                                       else
                                         nil
                                       end)
    }
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
       WHERE b.id=c.branch_id AND c.id=cl.center_id AND cl.id=l.client_id AND l.deleted_at is NULL AND cl.deleted_at is NULL
             #{condition}
       GROUP BY #{by_query}
    })    
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
end
