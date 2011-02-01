class ParByCenterReport < Report
  attr_accessor :date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id, :late_by_more_than_days, :late_by_less_than_days
  ParRow = Struct.new(:loan_count, :loan_amount, :par, :prin_overdue, :int_overdue, :fee_overdue, :tot_overdue)

  validates_with_method :date, :date_should_not_be_in_future

  def initialize(params,dates, user)
    @date   = dates.blank? ? Date.today : dates[:date]
    @name   = "PAR Report as on #{@date}"
    get_parameters(params, user)    
    @late_by_more_than_days ||= 0
  end

  def name
    extra = []    
    extra << "more than #{late_by_more_than_days} days" if late_by_more_than_days
    extra << "less than #{late_by_less_than_days} days" if late_by_less_than_days
    "PAR as on #{@date}: late by #{extra.join(' and ')}"
  end

  def self.name
    "PAR Report"
  end

  def include_late_day?(late_days)    
    late_days >= (@late_by_more_than_days) and late_days < (@late_by_less_than_days||INFINITY)
  end

  def generate
    # these are the loan history lines which represent the last line before @date
    selects = [:branch_id, :center_id, :days_overdue, :date, :amount_in_default, "l.amount amount", :actual_outstanding_principal]
    par_data = LoanHistory.defaulted_loan_info_by(:loan, @date, {:branch_id => @branch.map{|x| x.id}}, selects).group_by{|x| 
      x.center_id
    }

    data = {}
    loans = []
    @branch.each do |branch|
      data[branch] = {}
      @center.find_all{|c| c.branch_id==branch.id}.each do |center|    
        next unless par_data[center.id]

        par_data[center.id].each do |default|          
          if default.date and true and @date >= default.date - default.days_overdue
            late_by = default.days_overdue + (@date - default.date)
            next unless include_late_day?(late_by.to_i)
            data[branch][center] ||= ParRow.new(0, 0, 0, 0, 0, 0, 0)
            loans.push(default.loan_id)
            data[branch][center].loan_count   += 1
            data[branch][center].loan_amount  += default.amount
            data[branch][center].par          += default.actual_outstanding_principal
            data[branch][center].prin_overdue += default.pdiff
            data[branch][center].int_overdue  += (default.tdiff > default.pdiff ? default.tdiff - default.pdiff : 0)
            data[branch][center].tot_overdue  += default.tdiff
          end
        end
      end
    end

    overdue_fees = Fee.due(loans)
    @branch.each do |branch|
      @center.find_all{|c| c.branch_id==branch.id}.each do |center|
        next unless par_data[center.id]
        par_data[center.id].each do |default|
          data[branch][center].fee_overdue  += overdue_fees[default.loan_id].due if overdue_fees[default.loan_id]
        end
      end
    end
    return data
  end
end
