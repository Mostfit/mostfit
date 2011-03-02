class ParByStaffReport < Report
  attr_accessor :date, :branch, :branch_id
  ParRow = Struct.new(:less_than_30, :between_30_and_60, :between_60_and_90, :more_than_90)

  validates_with_method :date, :date_should_not_be_in_future

  validates_with_method :branch_id, :branch_should_be_selected

  def initialize(params,dates, user)
    @date   = dates.blank? ? Date.today : dates[:date]
    @name   = "PAR by staff report as on #{@date}"
    get_parameters(params, user)    
    @late_by_more_than_days ||= 0
  end

  def name
    "PAR by Staff report as on #{@date}"
  end

  def self.name
    "PAR by Staff report"
  end

  def generate
    # these are the loan history lines which represent the last line before @date
    selects = [:branch_id, :center_id, :days_overdue, :date, :amount_in_default, "l.amount amount", :actual_outstanding_principal]
    centers = {}
    # group by centers
    @center.each{|c|
      centers[c.id] = c
    }
    
    par_data = LoanHistory.defaulted_loan_info_by(:loan, @date, {:branch_id => @branch.map{|x| x.id}}, selects).group_by{|x| 
      centers[x.center_id].manager_staff_id
    }
    
    data = {}
    loans = []
    @branch.each do |branch|
      data[branch] = {}
      branch.centers.each do |center|
        next unless par_data[center.id]
        staff = center.manager

        par_data[center.id].each do |default|          
          if default.date and true and @date >= default.date - default.days_overdue
            late_by = default.days_overdue + (@date - default.date)
            data[branch][staff] ||= ParRow.new(0, 0, 0, 0)
            loans.push(default.loan_id)
            if late_by <= 30
              data[branch][staff].less_than_30       += default.actual_outstanding_principal
            elsif (late_by > 30 and late_by <= 60)
              data[branch][staff].between_30_and_60  += default.actual_outstanding_principal
            elsif (late_by > 60 and late_by <= 90)
              data[branch][staff].between_60_and_90  += default.actual_outstanding_principal
            elsif late_by > 90
              data[branch][staff].more_than_90       += default.actual_outstanding_principal
            end
          end
        end
      end
    end
    return data
  end
end
