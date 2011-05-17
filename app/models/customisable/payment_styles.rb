module Mostfit
  module Functions


    def get_divider
      case installment_frequency
      when :weekly
        52
      when :biweekly
        26
      when :monthly
        12
      when :daily
        365
      end    
    end

  end

  module PaymentStyles

    module Flat
      def scheduled_principal_for_installment(number)
        raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
        (amount.to_f / number_of_installments).round(2)
      end

      def scheduled_interest_for_installment(number) 
        raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
        (amount * interest_rate / number_of_installments).round(2)
      end
    end

    module EquatedWeekly
      
      def reducing_schedule
        return @reducing_schedule if @reducing_schedule
        @reducing_schedule = {}    
        balance = amount
        payment            = pmt(interest_rate/get_divider, number_of_installments, amount, 0, 0)
        1.upto(number_of_installments){|installment|
          @reducing_schedule[installment] = {}
          @reducing_schedule[installment][:interest_payable]  = ((balance * interest_rate) / get_divider).round(2)
          @reducing_schedule[installment][:principal_payable] = (payment - @reducing_schedule[installment][:interest_payable]).round(2)
          balance = balance - @reducing_schedule[installment][:principal_payable]
        }
        return @reducing_schedule
      end
      
      def scheduled_principal_for_installment(number)
        raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > number_of_installments
        return Loaner::Functions.reducing_schedule[number][:principal_payable]
      end

      def scheduled_principal_for_installment(number)
        raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > number_of_installments
        return Loaner::Functions.reducing_schedule[number][:interest_payable]
      end

    end

    module EquatedWeeklyRounded
    end


  end
end
