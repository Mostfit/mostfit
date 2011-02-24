class ParByStaffReport < Report
  attr_accessor :date, :branch
  ParRow = Struct.new(:less_than_30, :between_30_and_60, :between_60_and_90, :more_than_90)

  validates_with_method :date, :date_should_not_be_in_future

  def initialize(params,dates, user)
    @date   = dates.blank? ? Date.today : dates[:date]
    @name   = "PAR report by staff as on #{@date}"
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
    "PAR Report by Staff"
  end

  def include_late_day?(late_days)    
    late_days >= (@late_by_more_than_days) and late_days < (@late_by_less_than_days||INFINITY)
  end

  def generate
    # these are the loan history lines which represent the last line before @date
    selects = [:branch_id, :center_id, :days_overdue, :date, :amount_in_default, "l.amount amount", :actual_outstanding_principal]
    centers = {}
    # group by centers
    @center.each{|c|
      cenetrs[c.id] = c
    }
    
    par_data = LoanHistory.defaulted_loan_info_by(:loan, @date, {:branch_id => @branch.map{|x| x.id}}, selects).group_by{|x| 
      centers[x.center_id].manager_staff_id
    }
    
    data = {}
    loans = []
    @branch.each do |branch|
      data[branch] = {}
      branch.centers.each{|center|
        next unless par_data[center.id]
        staff = center.manager

        par_data[center.id].each do |default|          
          if default.date and true and @date >= default.date - default.days_overdue
            late_by = default.days_overdue + (@date - default.date)
            next unless include_late_day?(late_by.to_i)
            data[branch] ||= ParRow.new(0, 0, 0, 0)
            loans.push(default.loan_id)
            data[branch][staff].less_than_30       += 1
            data[branch][staff].between_30_and_60  += default.amount
            data[branch][staff].between_60_and_90  += default.actual_outstanding_principal
            data[branch][staff].more_than_90       += default.amount
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
