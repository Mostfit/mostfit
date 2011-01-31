class ParByCenterReport < Report
  attr_accessor :date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id, :late_by_more_than_days, :late_by_less_than_days
  ParRow = Struct.new(:loan_count, :loan_amount, :par, :default, :late_by_days)

  def initialize(params,dates, user)
    @date   = dates.blank? ? Date.today : dates[:date]
    @name   = "PAR Report as on #{@date}"
    get_parameters(params, user)
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
    late_days > (@late_by_more_than_days||0) and late_days < (@late_by_less_than_days||INFINITY)
  end

  def generate
    # these are the loan history lines which represent the last line before @date
    selects = [:branch_id, :center_id, :days_overdue, :date, :amount_in_default, "l.amount amount", :actual_outstanding_principal]
    par_data = LoanHistory.defaulted_loan_info_by(:loan, @date, {:branch_id => @branch.map{|x| x.id}, :center_id => @center.map{|x| x.id}}, selects).group_by{|x| 
      x.center_id
    }
    data = {}
    @branch.each do |branch|    
      data[branch] = {}
      @center.find_all{|c| c.branch_id==branch.id}.each do |center|    
        next unless par_data[center.id]

        par_data[center.id].each do |default|          
          if default.date and @date > default.date - default.days_overdue
            late_by = default.days_overdue + (@date - default.date)
            next unless include_late_day?(late_by.to_i)
            data[branch][center] ||= ParRow.new(0, 0, 0, 0, 0)
            
            data[branch][center].loan_count   += 1
            data[branch][center].loan_amount  += default.amount
            data[branch][center].par          += default.actual_outstanding_principal
            data[branch][center].default      += default.amount_in_default
          end
        end
      end
    end
    return data
  end
end
