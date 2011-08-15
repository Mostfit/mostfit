module Mostfit
  module PaymentStyles
    
    module PararthRounded

      def self.display_name
        "Rounded schedule (Pararth Rounded)"
      end

      def scheduled_principal_for_installment(number)
        raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
        rounding_schedule[number][:principal]
      end

      def scheduled_interest_for_installment(number)
        raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
        rounding_schedule[number][:interest]
      end

      def rounding_schedule
        return @_rounding_schedule if @_rounding_schedule
        @_rounding_schedule = {}
        return @_rounding_schedule unless amount.to_f > 0
        _prin_per_installment = amount.to_f / number_of_installments
        _total = amount * (1 + interest_rate) # cannot use total_to_be_received without blowing the universe up
        _installment = _total / number_of_installments
        rf = 0;
        (1..number_of_installments).to_a.each do |i| 
          prin = (_prin_per_installment + rf).send(loan_product.rounding_style)
          rf = _prin_per_installment - prin + rf
          int = (_installment - prin).send(loan_product.rounding_style)
          @_rounding_schedule[i] =  {:principal => prin, :interest => int}
        end
        return @_rounding_schedule
      end

      def clear_cache
        super
        @_rounding_schedule = nil
      end

      # repayment styles
      def pay_prorata(total, received_on)
        #adds up the principal and interest amounts that can be paid with this amount and prorates the amount
        i = used = prin = int = 0.0
        d = received_on
        total = total.to_f
        while used < total
          prin -= principal_overpaid_on(d).round(2)
          int  -= interest_overpaid_on(d).round(2)
          used  = (prin + int)
          d = client.center.next_meeting_date_from(d)
        end
        interest  = total * int/(prin + int)
        principal = total * prin/(prin + int)
        pfloat    = principal - principal.to_i
        ifloat    = interest  - interest.to_i
        pfloat > ifloat ? [interest - ifloat, principal + ifloat] : [interest + pfloat, principal - pfloat]
      end
    end #Pararth Rounded

    # pararth rounded with last principal less/more than usual
    module RoundedAtLastInstallmentLoan
      def self.display_name
        "Rounded with last principal and interest adjusted"
      end

      def scheduled_principal_for_installment(number)
        raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
        prin = (amount.to_f / number_of_installments)

        if number == number_of_installments
          ro_factor = prin - prin.send(loan_product.rounding_style)
          (prin.send(loan_product.rounding_style) + (number_of_installments - 1) * ro_factor).send(loan_product.rounding_style)
        else
          prin.send(loan_product.rounding_style)
        end
      end

      def scheduled_interest_for_installment(number)
        raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
        total = (amount.to_f * (1 + interest_rate) / number_of_installments)

        if number == number_of_installments
          ro_factor = total - total.send(loan_product.rounding_style)
          (total.send(loan_product.rounding_style) - scheduled_principal_for_installment(number) + (number_of_installments - 1) * ro_factor).send(loan_product.rounding_style)
        else
          total.send(loan_product.rounding_style) - scheduled_principal_for_installment(number)
        end       
      end
    end #RoundedAtLastInstallmentLoan

    # pararth rounded with last ineterst less/more than usual
    module RoundedPrincipalAndInterestLoan
      
      def self.extended(base)
        base.extend(Mostfit::PaymentStyles::ParathRounded)
      end
      
      def self.display_name
        "Rounded with last interest adjusted"
      end
      
      def scheduled_principal_for_installment(number)
        raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
        rounding_schedule[number][:principal].send(loan_product.rounding_style)
      end

      def scheduled_interest_for_installment(number)
        raise "number out of range, got #{number}" if number < 1 or number > number_of_installments
        if number == number_of_installments
          int_received_so_far = (1..(number-1)).map{|x| rounding_schedule[x][:interest]}.reduce(0){|s,x| s+=x}
          (amount * interest_rate - int_received_so_far).send(loan_product.rounding_style)
        else
          rounding_schedule[number][:interest].send(loan_product.rounding_style)
        end
      end
      
    end #RoundedPrincipalAndInterestLoan



  end
end
