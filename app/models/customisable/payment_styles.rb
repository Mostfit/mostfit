module Mostfit

  module PaymentStyles

    module Flat

      def pay_prorata(total, received_on)
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


      def scheduled_principal_for_installment(number)
        raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
        (amount.to_f / number_of_installments).round(2)
      end

      def scheduled_interest_for_installment(number) 
        raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
        (amount * interest_rate / number_of_installments).round(2)
      end
    end #Flat


    module EquatedWeekly

      def equated_payment
        ep = pmt(interest_rate/get_divider, number_of_installments, amount, 0, 0)
        ep.round_to_nearest(self.repayment_style.round_total_to, self.repayment_style.rounding_style)
      end

      def actual_number_of_installments
        reducing_schedule.count
      end

      def pay_prorata(total, received_on)
        i = used = prin = int = 0.0
        d = received_on
        total = total.to_f
        pmnt = equated_payment
        d = received_on
        curr_bal = actual_outstanding_principal_on(d)
        while (total - used) >= 0.01
          i_pmt = (interest_rate/get_divider * curr_bal).round(2)
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
        while balance > 0
          @_reducing_schedule[installment] = {}
          @_reducing_schedule[installment][:interest_payable]  = ((balance * interest_rate) / get_divider).round(2).round_to_nearest(self.repayment_style.round_interest_to, self.repayment_style.rounding_style)
          @_reducing_schedule[installment][:principal_payable] = [(payment - @_reducing_schedule[installment][:interest_payable]).round(2), balance].min
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
  end
end
