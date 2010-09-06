module Misfit

  module PaymentValidators
    # ALL payment validations go in here so that they are available to the loan product
    def amount_must_be_paid_in_full_or_not_at_all
      case type
        when :principal
          if amount < loan.scheduled_principal_due_on(received_on) and amount != 0
            return [false, "amount must be paid in full or not at all"]
          else
            return true
          end
        when :interest
          if amount < loan.scheduled_interest_due_on(received_on) and amount != 0
            return [false, "amount must be paid in full or not at all"]
          else
            return true
          end
        else
          return true
      end
    end

    def fees_applicable_to_loan_paid_before_first_payment?
      if self.loan and (type==:principal or type==:interest) and loan.payments(:type => [:principal, :interest]).count==0
        if not loan.fees_paid?
          return [false, "All fees applicable to this loan are not paid yet"] 
        end
      end
      return true
    end

    def fees_applicable_to_client_paid_before_first_payment?
      if self.loan and (type==:principal or type==:interest) and loan.payments(:type => [:principal, :interest]).count==0
        if not loan.client.fees_paid?
          return [false, "All fees applicable to this client are not paid yet"]
        end
      end
      return true
    end

  end    #PaymentValidators

  module LoanValidators
    def installments_are_integers?
      return [false, "Number of installments not defined"] if number_of_installments.nil? or number_of_installments.blank?
      return [false, "Amount not defined"] unless amount
      return [false, "Interest rate not defined"] unless interest_rate

      self.payment_schedule.each do |date, val|
        pri = val[:principal]
        int = val[:interest]
        return [false, "Amount must yield integer installments"] if (pri+int).to_i != (pri+int)
      end
      return true
    end
    
    def part_of_a_group_and_passed_grt?
      return [false, "Client is not part of a group"] if not client or client.client_group_id.nil? or client.client_group_id.blank?
      return [false, "Client has not passed GRT"] if client.grt_pass_date.nil? or client.grt_pass_date.blank?
      return true
    end

    def scheduled_dates_must_be_center_meeting_days
      return [false, "Not client defined"] if not client
      center = client.center
      failed = []
      correct_weekday = nil 
      ["scheduled_first_payment_date", "scheduled_disbursal_date"].each do |d|
        if not date = instance_eval(d) or not date.weekday == center.meeting_day_for(date)
          failed << d 
          correct_weekday = center.meeting_day_for(date)
        end
      end
      return [false, "#{failed.join(",")} must be #{correct_weekday}"]      unless failed.blank?
      return true
    end

    def insurance_must_be_mandatory
      return [false, "Client does not have an insurance"] if client.insurance_policies.nil? or client.insurance_policies.length==0
      return [false, "Insurance is not valid anymore"]    if client.insurance_policies.sort_by{|x| x.date_to}.last.date_to <= self.applied_on
      return [false, "Insurance is not active"]           if not client.insurance_policies.collect{|x| x.status}.include?(:active)
      return true
    end

    def client_fee_should_be_paid
      if self.new? and not client.fees_paid?
        return [false, "All fees applicable to this client are not paid yet"]
      end
      return true
    end

  end    #LoanValidators

end


