class AggregateConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id, :group_by_types
  Year = Struct.new(:name)

  validates_with_method :from_date, :date_should_not_be_in_future

  @@group_by = {:branch => :branch_id, :center => :center_id, :client_group => :client_group_id, :staff_member => :disbursed_by_staff_id,
    :year => :year, :month => :month}

  validates_with_method :group_by_types, :group_by_should_be_present

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    @group_by_types = group_types[params[:group_by_types].to_sym] if params and params[:group_by_types] and not params[:group_by_types].blank?
    get_parameters(params, user)
  end
  
  def group_types
    {
      :branch => [:branch], :branch_center => [:branch, :center], :branch_center_group => [:branch, :center, :client_group], 
      :branch_staff => [:branch, :staff_member], :branch_staff_center => [:branch, :staff_member, :center],
#      :branch_year => [:branch, :year], :year => [:year], :year_quarter => [:year, :quarter], :year_quarter_month => [:year, :quarter, :month],
#      :year_quarter_month_branch => [:year, :quarter, :month, :branch], :year_quarter_month_staff => [:year, :quarter, :month, :staff],
#      :year_quarter_branch => [:year, :quarter, :branch], :year_branch => [:year, :branch]
    }
  end

  def name
    "Aggregate Consolidated Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Aggregate Consolidated report"
  end
  
  def generate
    set_cache
    extra     = []
    extra    << "l.loan_product_id = #{loan_product_id}" if loan_product_id
    extra    << "lh.branch_id in (#{@branch.map{|b| b.id}.join(', ')})" if @branch.length > 0 and self.branch_id
    extra    << "lh.center_id in (#{@center.map{|c| c.id}.join(', ')})" if @center.length > 0
    # if a funder is selected
    if @funder
      funder_loan_ids = @funder.loan_ids
      funder_loan_ids = ["NULL"] if funder_loan_ids.length == 0
      extra    << "l.id in (#{funder_loan_ids.join(", ")})" 
    end
    
    # grouping by date type is fundamentally different
    if @group_by_types.include?(:year) or @group_by_types.include?(:quarter) or @group_by_types.include?(:month)      
      group_by_types = @group_by_types - [:year, :quarter, :month]
      group_by_types = true if group_by_types.blank?
      data         = {}

      @group_by_types.each_with_index{|group_by_type, idx|
        if [:year, :quarter, :month].include?(group_by_type)          
          get_dates(group_by_type).each{|from_date, to_date|
            disbursement = LoanHistory.sum_disbursed_grouped_by(group_by_types, from_date, to_date, extra)
            outstanding  = LoanHistory.sum_outstanding_grouped_by(to_date, group_by_types, extra)
            repaid       = LoanHistory.sum_repaid_grouped_by(group_by_types, from_date, to_date, extra)
            foreclosure  = LoanHistory.sum_foreclosure_grouped_by(group_by_types, from_date, to_date, extra)
            data[Year.new(from_date.send(group_by_type).to_s)] = aggregate_data(disbursement, outstanding, repaid, foreclosure)
          }
        end
      }
    else
      disbursement = LoanHistory.sum_disbursed_grouped_by(@group_by_types, @from_date, @to_date, extra)
      outstanding  = LoanHistory.sum_outstanding_grouped_by(@to_date, @group_by_types, extra)
      repaid       = LoanHistory.sum_repaid_grouped_by(@group_by_types, @from_date, @to_date, extra)
      foreclosure  = LoanHistory.sum_foreclosure_grouped_by(@group_by_types, @from_date, @to_date, extra)
      overdue      = LoanHistory.defaulted_loan_info_by(@group_by_types, @to_date, extra, "count(distinct(lh.loan_id)) loan_count")
      advance      = LoanHistory.advance_balance(@to_date, @group_by_types, extra, "count(distinct(lh.loan_id)) loan_count")

      length = @group_by_types.length
      
      disbursements = send("group_by_#{length}", disbursement, @group_by_types)
      outstandings  = send("group_by_#{length}", outstanding, @group_by_types)
      repaids       = send("group_by_#{length}", repaid, @group_by_types)
      foreclosures  = send("group_by_#{length}", foreclosure, @group_by_types)
      overdues      = send("group_by_#{length}", overdue, @group_by_types)
      advances      = send("group_by_#{length}", advance, @group_by_types)
      
      data = group_aggregation(disbursements, outstandings, repaids, foreclosures, overdues, advances, @group_by_types)
    end
    return data
  end

  private
  def group_aggregation(disbursements, outstandings, repaids, foreclosures, overdues, advances, group_by_types)
    disbursements ||= {}
    outstandings  ||= {}
    repaids       ||= {}
    foreclosures  ||= {}
    overdues      ||= {}
    advances      ||= {}

    if group_by_types.length > 1
      [disbursements.keys + outstandings.keys + repaids.keys + foreclosures.keys + overdues.keys, advances.keys].flatten.uniq.map{|key|
        {key => group_aggregation(disbursements[key], outstandings[key], repaids[key], foreclosures[key], overdues[key], advances[key], group_by_types[1..-1])}
      }.reduce({}){|s,x| s+=x}
    else
      [disbursements.keys + outstandings.keys + repaids.keys + foreclosures.keys, overdues.keys, advances.keys].flatten.uniq.map{|key|
        [key, aggregate_data(disbursements[key], outstandings[key], repaids[key], foreclosures[key], overdues[key], advances[key])]
      }.to_hash
    end
  end
  
  def aggregate_data(disbursements, outstandings, repaids, foreclosures, overdues, advances)
    data ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    disbursements.each{|d|
      data[0]  += d.loan_count
      data[1]  += d.loan_amount
    } if disbursements

    repaids.each{|r|
      data[2]  += r.loan_count  || 0
      data[3]  += r.loan_amount || 0
    } if repaids

    foreclosures.each{|f|
      data[4]  += f.loan_count || 0
      data[5]  += f.loan_amount || 0
    } if foreclosures

    outstandings.each{|o|
      data[6]  += o.loan_count || 0
      data[7]  += o.actual_outstanding_principal || 0
    } if outstandings

    overdues.each{|o|
      data[8]  += o.loan_count || 0
      data[9]  += o.pdiff || 0
    } if overdues

    advances.each{|o|
      data[10]  += o.loan_count || 0
      data[11]  += o.balance_total || 0
    } if advances
    data
  end
  

  def group_by_1(data, types)
    data.group_by{|x|
      get_obj(types[0], x.send(@@group_by[types[0]]))
    }
  end

  def group_by_2(data, types)
    data.group_by{|x|
      get_obj(types[0], x.send(@@group_by[types[0]]))
    }.map{|ab, rows|
      {ab => rows.group_by{|x| get_obj(types[1], x.send(@@group_by[types[1]]))}}
    }.reduce({}){|s,x| s.merge(x)}
  end

  def group_by_3(data, types)
    data.group_by{|x|
      get_obj(types[0], x.send(@@group_by[types[0]]))
    }.map{|ab, rows| 
      {ab => rows.group_by{|x| get_obj(types[1], x.send(@@group_by[types[1]]))}.map{|bc, rows1| 
          {bc => rows1.group_by{|x| get_obj(types[2], x.send(@@group_by[types[2]]))}}
        }.reduce({}){|s,x| s.merge(x)}
      }
    }.reduce({}){|s,x| s.merge(x)}
  end

  def get_obj(klass_type, id)
    if klass_type == :branch
      @branch.find{|b| b.id == id}
    elsif klass_type == :center
      @center.find{|b| b.id == id}
    elsif klass_type == :client_group
      ClientGroup.get(id)
    elsif klass_type == :staff_member
      @staff_members[id]
    elsif klass_type == :year
      Year.new(id)
    end
  end

  def set_cache
    if @group_by_types.include?(:staff_member)
      @staff_members = {}
      StaffMember.all.map{|st|
        @staff_members[st.id] = st
      }
    end
  end    

  def get_dates(date_type)
    dates = []
    years   = (@from_date.year..@to_date.year).to_a
    if date_type == :month
      years.each{|year|
        (1..12).to_a.each{|month|
          month_start_date = Date.new(year, month, 1)
          month_end_date   = Date.new(year, month, -1)
          dates.push([month_start_date, month_end_date]) if month_start_date >= @from_date and  month_end_date <= @to_date            
        }
      }
    elsif date_type == :quarter
    else
      years.each{|year|
        year_start_date = Date.new(year, 1, 1)
        year_end_date   = Date.new(year, 12, 31)
        dates.push([year_start_date, year_end_date]) if year_start_date >= @from_date and  year_end_date <= @to_date
      }
    end
    dates
  end

  def group_by_should_be_present
    return [false, "No group by selected"] unless @group_by_types
    return true
  end
end
