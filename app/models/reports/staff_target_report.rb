#This report gives the Target Report for the staff members to check their performance on monthly basis.
class StaffTargetReport < Report
  attr_accessor :branch_id, :branch, :to_date, :area_id, :area, :type_of_target

  validates_with_method :branch_id, :method => :branch_or_area_present

  def initialize(params, dates, user)
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @from_date = Date.new(@to_date.year, @to_date.month, 01)
    @name = "Staff Target Report from #{@from_date} to #{@to_date}"
    @type_of_target = (params and params[:type_of_target]) ? params[:type_of_target] : :relative
    get_parameters(params, user)
  end

  def name
    "Staff Target Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Staff Target Report"
  end

  def generate
    data, staff_members, outstanding, amount_outstanding, total_outstanding = {}, {}, {}, {}, {}
    overdue_repayment = 0
    @center.map{|center| 
      staff_members[center.manager] ||= []
      staff_members[center.manager].push(center)
    }

    #this gives all the center_ids who have there payments to be made today
    outstandings_past  = LoanHistory.sum_outstanding_grouped_by(@to_date - 1, :center, {:center_id => @center.map{|c| c.id}})
    outstandings_today = LoanHistory.sum_outstanding_grouped_by(@to_date, :center, {:center_id => @center.map{|c| c.id}})
    staff_members.each{|staff, centers|
      center_ids = centers.map{|c| c.id}
      outstanding[staff] = outstandings_today.find_all{|row| center_ids.include?(row.center_id)}.map{|x| x[0].to_i}.reduce(0){|s,x| s+=x}
    }
    
    target_amount, target_number = Hash.new(0), Hash.new(0)
    
    #calculates the target attached to a staff member for disbursed loan amount for this month.
    Target.all(:attached_to => :staff_member, :target_of => :loan_disbursement_by_amount, :attached_id => staff_members.keys.map{|sm| sm.id},
               :target_type => @type_of_target,
               :start_date.gte => @from_date,
               :deadline.lte => Date.new(@to_date.year, @to_date.month, -1)).group_by{|t| t.attached_id}.each{|staff_id, targets|
      target_amount[staff_id] ||= 0
      target_amount[staff_id] += targets.map{|t| (t.target_value - t.start_value)}.reduce(0){|s,x| s+=x} if targets
    }

    #calculates the target attached to a staff member for no. of clients registered this month.
    Target.all(:attached_to => :staff_member, :target_of => :client_registration, :attached_id => staff_members.keys.map{|sm| sm.id},
               :target_type => @type_of_target, :start_date.gte => @from_date,
               :deadline.lte => Date.new(@to_date.year, @to_date.month, -1)).group_by{|t| t.attached_id}.each{|staff_id, targets|
      target_number[staff_id] ||= 0
      target_number[staff_id] += targets.map{|t| (t.target_value - t.start_value)}.reduce(0){|s,x| s+=x} if targets
    }

    #loop to calculate different values according to each staff member.
    staff_members.each {|staff, centers|      
      # calculates overdue loan amount for current month per staff member.
      overdue_loan = Loan.all(:scheduled_disbursal_date.lte => @to_date, :approved_on.lte => @to_date, :disbursal_date => nil,
                              :applied_by => staff, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i

      #calculates the loan sanctioned amount.
      sanctioned_loan = Loan.all(:approved_on.not => nil, :approved_by => staff, :scheduled_disbursal_date.lte => @to_date, :disbursal_date => nil,
                                 :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i

      #calculates the total loan by adding overdue_loan and sanctioned_loan.
      total_loan = overdue_loan + sanctioned_loan
      
      #calculates the amount disbursed.
      disbursed_loan = Loan.all(:approved_on.lte => @to_date, :scheduled_disbursal_date.lte => @to_date, :disbursed_by => staff,
                                :disbursal_date => @to_date, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i

      #calculates the overdue repayment amount and displays only if not nil otherwise displays a 0.
      repayment = LoanHistory.defaulted_loan_info_for(staff, @to_date, nil, :aggregate, :managed)
      if repayment
        overdue_repayment = repayment.principal_due.to_i
      else
        overdue_repayment = 0
      end

      #calculates the actual payment received today.
      actual_repayment = Payment.all(:received_on => @to_date, :received_by => staff).aggregate(:amount.sum).to_i

      #calculates the variance by comparing due and actual_repayment and substracting the values.
      variance = outstanding[staff] - actual_repayment

      #calculates actual client created today.
      actual_client_created_date      = Client.all(:date_joined => @to_date, :created_by_staff_member_id => staff.id).count

      #calculates actual client created till today from 1st day of current month.
      actual_client_created_till_date = Client.all(:date_joined.gte => @from_date, :date_joined.lte => @to_date, :created_by_staff_member_id => staff.id).count

      #calculates the variance by comparing the target attached and the actual number of clients created till date and substraction the values.
      target_variance = target_number[staff.id] - actual_client_created_till_date
    
      #calculates the total outstanding amount and displays only if the value is not false otherwise 0 is displayed.
      amount_outstanding[staff] = LoanHistory.sum_outstanding_for(staff, @to_date, :managed)
      if amount_outstanding[staff] and amount_outstanding[staff][0]
        total_outstanding[staff] = amount_outstanding[staff][0].actual_outstanding_principal.to_i
      else
        total_outstanding[staff] = 0
      end

      #calculates disbursed loan amount for the current month.
      till_date_loan_amount = Loan.all(:disbursed_by => staff, :disbursal_date.gte => @from_date,
                                       :disbursal_date.lte => @to_date, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum)

      #fills in the values to be displayed in the report in the variable data which is an array.
      data[staff.name] = {:development => {
          :target => [target_number[staff.id]],
          :actual => [actual_client_created_date, actual_client_created_till_date], :variance => (target_variance).abs},
        :disbursement => {:target => [target_amount[staff.id]],
          :till_date => [
                         Loan.count(:disbursed_by => staff, :disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date,
                                    :rejected_on => nil, :written_off_on => nil), 
                         till_date_loan_amount
                        ],
          :today => {
            :overdue => overdue_loan, 
            :sanctioned => sanctioned_loan, 
            :total => total_loan,
            :disbursed => disbursed_loan,
            :variance_from_sanctioned => (total_loan - disbursed_loan).abs,
            :variance_from_target => (target_amount[staff.id] - (till_date_loan_amount || 0) - disbursed_loan).abs
          }
        }, 
        :repayment => {
          :var => overdue_repayment, 
          :due => outstanding[staff], 
          :actual => actual_repayment, 
          :total_variance => variance.abs,
          :variance_till_date => (overdue_repayment + variance).abs 
        }, 
        :total_outstanding => total_outstanding[staff]
      }
    }
    return data
  end

  def branch_or_area_present
    return [false, "Either branch or area should be selected"] if (branch_id and area_id) or (not branch_id and not area_id)
    return true
  end
  
end
