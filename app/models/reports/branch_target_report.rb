class BranchTargetReport < Report
  attr_accessor :branches, :branch_id, :from_date, :to_date

  def initialize(params, dates, user)
    @date = Date.today
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.new(@date.year, @date.month, 01)
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.new(@date.year, @date.month, -1)
    @name = "Branch Target Report from #{from_date} to #{to_date}"
    get_parameters(params, user)
  end

  def name
    "Branch Target Report from #{from_date} to #{to_date}"
  end

  def self.name
    "Branch Target Report"
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
      outstanding[staff] = outstandings_past.find_all{|row| center_ids.include?(row.center_id)}.map{|x| x[0].to_i}.reduce(0){|s,x| s+=x}
    }
    
    target_amount, target_number = Hash.new(0), Hash.new(0)
    
    # payments_today  = LoanHistory.all(:date => @date, :center_id => @center).aggregate(:center_id, :principal_paid.sum, :interest_paid.sum)
    Target.all(:attached_to => :staff_member, :type => :loan_disbursement_by_amount, :attached_id => staff_members.keys.map{|sm| sm.id},
               :created_at.gte => Date.new(@from_date.year, @from_date.month, 01),
               :deadline.lte => Date.new(@to_date.year, @to_date.month, -1)).group_by{|t| t.attached_id}.each{|staff_id, targets|
      target_amount[staff_id] ||= 0
      target_amount[staff_id] += targets.map{|t| t.target_value}.reduce(0){|s,x| s+=x} if targets
    }
    
    Target.all(:attached_to => :staff_member, :type => :client_registration, :attached_id => staff_members.keys.map{|sm| sm.id},
               :created_at.gte => Date.new(@from_date.year, @from_date.month, 01),
               :deadline.lte => Date.new(@to_date.year, @to_date.month, -1)).group_by{|t| t.attached_id}.each{|staff_id, targets|
      target_number[staff_id] ||= 0
      target_number[staff_id] += targets.map{|t| t.target_value}.reduce(0){|s,x| s+=x} if targets
    }
    
    staff_members.each {|staff, centers|      
      overdue_loan = Loan.all(:scheduled_disbursal_date.gte => Date.new(@from_date.year, @from_date.month, 1),
                              :scheduled_disbursal_date.lte => @to_date, :approved_on.not => nil, 
                              :disbursal_date => nil, :applied_by => staff, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum) || 0 
      
      sanctioned_loan = Loan.all(:approved_on.lte => @to_date, :approved_by => staff, :scheduled_disbursal_date => @to_date,
                                 :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum) || 0         #calculates the loan sanctioned amount.
      
      total_loan = overdue_loan + sanctioned_loan
      
      disbursed_loan = LoanHistory.amount_disbursed_for(staff, :from_date => Date.new(@from_date.year, @from_date.month, 1),
                                                        :to_date => @to_date).amount.to_i   #calculates the amount disbursed.
      
      repayment = LoanHistory.defaulted_loan_info_for(staff, @to_date)#this calculates the overdue amount and displays value if not nil
      if repayment != nil
        overdue_repayment = repayment.principal_due.to_i
      else
        overdue_repayment = 0
      end
      
      actual_repayment = Payment.all(:received_on => @to_date, :received_by => staff).aggregate(:amount.sum).to_i  #calculates the payment received.
      
      variance = outstanding[staff] - actual_repayment
      
      actual_client_created_date      = Client.all(:date_joined => @to_date, :created_by_staff_member_id => staff.id).count
      actual_client_created_till_date = Client.all(:date_joined.gte => Date.new(@from_date.year, @from_date.month, 1), :date_joined.lte => @to_date,
                                                   :created_by_staff_member_id => staff.id).count
      
      target_variance = target_number[staff.id] - actual_client_created_till_date
      
      amount_outstanding[staff] = LoanHistory.sum_outstanding_for(staff, @to_date)  #this calculates the outstanding amount and displays if the value is not false.
      if amount_outstanding[staff] != false
        total_outstanding[staff] = amount_outstanding[staff][0].actual_outstanding_principal.to_i
      else
        total_outstanding[staff] = 0
      end
      
      till_date_loan_amount = Loan.all(:disbursed_by => staff, :disbursal_date.gte => Date.new(@from_date.year, @from_date.month, 1),
                                       :disbursal_date.lte => @to_date, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum)

      data[staff.name] = {:development => {
          :target => [target_number[staff.id]],
          :actual => [actual_client_created_date, actual_client_created_till_date], :variance => target_variance
        }, 
        :disbursement => {:target => [target_amount[staff.id]],
          :till_date => [
                         Loan.count(:disbursed_by => staff, :disbursal_date.gte => Date.new(@from_date.year, @from_date.month, 1),
                                    :disbursal_date.lte => @to_date, :rejected_on => nil, :written_off_on => nil), 
                         till_date_loan_amount
                        ],
          :today => {
            :overdue => overdue_loan, 
            :sanctioned => sanctioned_loan, 
            :total => total_loan,
            :disbursed => disbursed_loan,
            :variance_from_sanctioned => (total_loan - disbursed_loan),
            :variance_from_target => (target_amount[staff.id] - (till_date_loan_amount || 0) - disbursed_loan)
          }
        }, 
        :repayment => {
          :var => overdue_repayment, 
          :due => outstanding[staff], 
          :actual => actual_repayment, 
          :total_variance => variance,
          :variance_till_date => (overdue_repayment + variance) 
        }, 
        :total_outstanding => total_outstanding[staff]
      }
    }
    return data
  end
end
