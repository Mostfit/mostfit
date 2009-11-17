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
      end
    end

    def other_validation
      return [false, "other validation failed"]
    end
  end    #PaymentValidators

  module LoanValidators
    def installments_are_integers?
      return true
      return [false, "Number of installments not defined"] if number_of_installments.nil? or number_of_installments.blank?
      (1..number_of_installments).each do |i|
        p = scheduled_principal_for_installment(i)
        return [false, "Amount must yield integer installments"] if p.to_i != p
      end
      return true
    end
  end    #LoanValidators

end


