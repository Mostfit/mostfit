class BranchTargetReport < Report
  attr_accessor :branch_id, :date, :branch
  
  def initialize(params, dates, user)
    @date = dates[:date]||Date.today
    @name = "Branch Target Report for #{date}"
    get_parameters(params, user)
  end

  def name
    "Branch Target Report for #{date}"
  end

  def self.name
    "Branch Target Report"
  end

  def generate
    data, staff_members, outstanding = {}, {}, {}
    @center.map{|center| 
      staff_members[center.manager] ||= []
      staff_members[center.manager].push(center)      
    }
  
    #this gives all the center_ids who have there payments to be made today
    outstandings_past  = LoanHistory.sum_outstanding_grouped_by(@date - 1, :center, {:center_id => @center.map{|c| c.id}})
    outstandings_today = LoanHistory.sum_outstanding_grouped_by(@date, :center, {:center_id => @center.map{|c| c.id}})
    staff_members.each{|staff, centers|
      center_ids = centers.map{|c| c.id}
      outstanding[staff] = outstandings_past.find_all{|row| center_ids.include?(row.center_id)}.map{|x| x[0].to_i}.reduce(0){|s,x| s+=x}
    }

    target_amount, target_number = {}, {}

    # payments_today  = LoanHistory.all(:date => @date, :center_id => @center).aggregate(:center_id, :principal_paid.sum, :interest_paid.sum)

    staff_members.each {|staff, centers|      
      overdue_loan = Loan.all(:scheduled_disbursal_date.lte => @date, :approved_on.not => nil, 
                              :disbursal_date => nil, :applied_by => staff, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum) || 0 
   
      Target.all(:attached_to => :staff_member, :type => :loan_disbursement_by_amount, :attached_id => staff.id,
                 :created_at.gte => Date.new(@date.year, @date.month, 01),
                 :deadline.lte => Date.new(@date.year, @date.month, -1)).each{|target|
        target_amount ||= 0
        target_amount = target.target_value
      }
      
      Target.all(:attached_to => :staff_member, :type => :client_registration, :attached_id => staff.id,
                 :created_at.gte => Date.new(@date.year, @date.month, 01),
                 :deadline.lte => Date.new(@date.year, @date.month, -1)).each{|target|
        target_number ||= 0
        target_number = target.target_value
      }
      
      sanctioned_loan = Loan.all(:approved_on => @date, :approved_by => staff, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum) || 0
      
      total_loan = overdue_loan + sanctioned_loan
      
      disbursed_loan = Loan.all(:disbursal_date => @date, :disbursed_by => staff, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum) || 0

      overdue_repayment = 0 #TODO - need to calculate the loan overdue for today.

      actual_repayment = Payment.all(:received_on => @date, :received_by => staff).aggregate(:amount.sum).to_i

      variance = outstanding[staff] - actual_repayment

      actual_client_created_date      = Client.all(:date_joined => @date, :created_by_staff_member_id => staff.id).count
      actual_client_created_till_date = Client.all(:date_joined.lte => @date, :created_by_staff_member_id => staff.id).count

      target_variance = target_number - actual_client_created_till_date
      #the target values are showing right but they are showing for all staff members.
      data[staff] = {:development => {:target => [target_number, target_amount],
          :actual => [actual_client_created_date, actual_client_created_till_date], :variance => target_variance}, 
        :disbursement => {:till_date => [
                                         Loan.count(:disbursed_by => staff, :disbursal_date.lte => @date, :rejected_on => nil, :written_off_on => nil), 
                                         Loan.all(:disbursed_by => staff, :disbursal_date.lte => @date, :rejected_on => nil,
                                                  :written_off_on => nil).aggregate(:amount.sum)
                                        ], 
          :today => {
            :overdue => overdue_loan, 
            :sanctioned => sanctioned_loan, 
            :total => total_loan,
            :disbursed => disbursed_loan,
            :variance => (total_loan - disbursed_loan)
          }
        }, 
        :repayment => {
          :var => overdue_repayment, 
          :due => outstanding[staff], 
          :actual => actual_repayment, 
          :total_variance => variance,
          :variance_till_date => (overdue_repayment + variance) 
        }, 
        :total_outstanding => outstanding[staff] 
      }
    }
    return data
  end  
end
