module Mostfit

  module PaymentStyles

    module Flat

      def pay_prorata(total, received_on, curr_bal = nil)
        #adds up the principal and interest amounts that can be paid with this amount and prorates the amount
        i = used = prin = int = 0.0
        d = received_on
        total = total.to_f
        while used < total
          prin += scheduled_principal_for_installment(installment_for_date(d)).round(2)
          int  += scheduled_interest_for_installment(installment_for_date(d)).round(2)
          used  = (prin + int)
          d = shift_date_by_installments(d, 1)
        end
        interest  = total * int/(prin + int)
        principal = total * prin/(prin + int)
        [interest, principal]
      end

      def pay_normal
        
      end

      def actual_number_of_installments
        reducing_schedule.count
      end


      def reducing_schedule
        return @_reducing_schedule if @_reducing_schedule
        @_reducing_schedule = {}    
        balance = amount
        payment            = amount * (1 + interest_rate) / number_of_installments
        total_int_paid  = 0
        installment = 1
        while balance > 0
          @_reducing_schedule[installment] = {}
          int_paid = [interest_calculation, (amount * interest_rate) - total_int_paid].min
          @_reducing_schedule[installment][:interest_payable]  = int_paid
          total_int_paid += int_paid
          if rs.force_num_installments and installment == number_of_installments
            prin_paid = balance
          else
            prin_paid = [payment - int_paid, balance].min
          end
          @_reducing_schedule[installment][:principal_payable] = prin_paid
          balance = balance - prin_paid
          installment += 1
        end
        return @_reducing_schedule
      end

      def interest_calculation
        (amount * interest_rate / number_of_installments).round(2).round_to_nearest(rs.round_interest_to, rs.rounding_style)
      end

      def scheduled_principal_for_installment(number)
        raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > actual_number_of_installments
        return reducing_schedule[number][:principal_payable]
      end

      def scheduled_interest_for_installment(number)
        raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > actual_number_of_installments
        return reducing_schedule[number][:interest_payable]
      end

    end #Flat


    module EquatedWeekly

      def equated_payment
        ep = pmt(interest_rate/get_divider, number_of_installments, amount, 0, 0)
        rs = self.repayment_style || self.loan_product.repayment_style
        ep.round_to_nearest(rs.round_total_to, rs.rounding_style)
      end

      def actual_number_of_installments
        reducing_schedule.count
      end

      def pay_prorata(total, received_on, curr_bal = nil)
        i = used = prin = int = 0.0
        d = received_on
        total = total.to_f
        pmnt = equated_payment
        d = received_on
        curr_bal ||= actual_outstanding_principal_on(d)
        while (total - used) >= 0.01
          i_pmt = interest_calculation(curr_bal)
          int += i_pmt
          p_pmt = pmnt - i_pmt
          prin += p_pmt
          curr_bal -= p_pmt
          used  = (prin + int)
          d = shift_date_by_installments(d, 1)
        end
        interest  = total * int/(prin + int)
        principal = total * prin/(prin + int)
        [interest, principal]
      end

        
        

      def reducing_schedule
        return @_reducing_schedule if @_reducing_schedule
        @_reducing_schedule = {}    
        balance = amount
        payment            = equated_payment
        installment = 1
        rs = self.repayment_style || self.loan_product.repayment_style
        
        while balance > 0
          @_reducing_schedule[installment] = {}
          @_reducing_schedule[installment][:interest_payable]  = interest_calculation(balance)
          if rs.force_num_installments and installment == number_of_installments
            @_reducing_schedule[installment][:principal_payable] = balance
          else
            @_reducing_schedule[installment][:principal_payable] = [(payment - @_reducing_schedule[installment][:interest_payable]).round(2), balance].min
          end
          balance = balance - @_reducing_schedule[installment][:principal_payable]
          installment += 1
        end
        return @_reducing_schedule
      end
      
      def scheduled_principal_for_installment(number)
        raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > actual_number_of_installments
        return reducing_schedule[number][:principal_payable]
      end

      def scheduled_interest_for_installment(number)
        raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > actual_number_of_installments
        return reducing_schedule[number][:interest_payable]
      end

    end #EquatedWeekly

    module BulletLoan

  
      def self.display_name
        "Single shot repayment (Bullet Loan)"
      end
      
      def scheduled_interest_for_installment(number = 1)
        amount * interest_rate
      end
  
      def scheduled_principal_for_installment(number = 1)
        amount
      end

      def scheduled_interest_up_to(date)
        return scheduled_interest_for_installment(1) if date > scheduled_first_payment_date
        scheduled_interest_for_installment(1) * (1 - (scheduled_first_payment_date - date) / (scheduled_first_payment_date - disbursal_date||scheduled_disbursal_date))
      end
      
      def pay_prorata(total, received_on, cur_bal = 0)
        #adds up the principal and interest amounts that can be paid with this amount and prorates the amount
        int  = scheduled_interest_up_to(received_on)
        int -= interest_received_up_to(received_on)
        prin = total - int
        [int, prin]
      end

  
      private
      def set_installments_to_1
        number_of_installments = 1
      end
    end #BulletLoan

    module BulletLoanWithPeriodicInterest

      def self.display_name
        "Single shot principal with periodic interest (Bullet Loan With Periodic Interest)"
      end
  
      def pay_prorata(total, received_on, curbal = 0)
        #adds up the principal and interest amounts that can be paid with this amount and prorates the amount
        int  = scheduled_interest_up_to(received_on)
        int -= interest_received_up_to(received_on)
        prin = total - int
        [int, prin]
      end


      def scheduled_interest_for_installment(number)
        raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
        (amount * interest_rate / number_of_installments).round(2).round_to_nearest(rs.round_interest_to, rs.rounding_style)
      end

      def scheduled_principal_for_installment(number)
        return 0 if number < number_of_installments
        return amount if number == number_of_installments
      end
  
      def scheduled_interest_up_to(date);  get_scheduled(:total_interest,  date); end

    end #BulletLoanWithPeriodicInterest

    module CustomPrincipal
      
      def reducing_schedule
        return @_reducing_schedule if @_reducing_schedule
        @_reducing_schedule = {}    
        balance = amount
        installment = 1
        while balance > 0
          @_reducing_schedule[installment] = {}
          @_reducing_schedule[installment][:interest_payable]  = interest_calculation(balance)
          if rs.force_num_installments and installment == number_of_installments
            @_reducing_schedule[installment][:principal_payable] = balance
          else
            @_reducing_schedule[installment][:principal_payable] = scheduled_principal_for_installment(installment)
          end
          balance = balance - @_reducing_schedule[installment][:principal_payable]
          installment += 1
        end
        return @_reducing_schedule
      end        
      
      def scheduled_principal_for_installment(number)
        rs.principal_schedule[number - 1]
      end

      def scheduled_interest_for_installment(number)
        reducing_schedule[number]
      end


    end

    module CustomPrincipalAndInterest
      def pay_prorata(total, received_on, curr_bal = nil)
        #adds up the principal and interest amounts that can be paid with this amount and prorates the amount
        i = used = prin = int = 0.0
        d = received_on
        total = total.to_f
        prin_due = info(d)[:principal_due]
        int_due  = info(d)[:interest_due]
        if prin_due and int_due
          prin = prin_due
          int = int_due
          used += (int + prin)
        end
        while used < total
          prin += scheduled_principal_for_installment(installment_for_date(d)).round(2)
          int  += scheduled_interest_for_installment(installment_for_date(d)).round(2)
          used  = (prin + int)
          d = shift_date_by_installments(d, 1)
        end
        interest  = total * int/(prin + int)
        principal = total * prin/(prin + int)
        [interest, principal]
      end

      def scheduled_principal_for_installment(number)
        rs.principal_schedule(amount.to_i)[number - 1]
      end

      def scheduled_interest_for_installment(number)
        rs.interest_schedule(amount.to_i)[number - 1]
      end

    end
      



  end
end
