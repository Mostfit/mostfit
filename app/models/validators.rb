module Misfit
  # ALL payment validations go in here so that they are available to the loan product
  module PaymentValidators
    def amount_must_be_paid_in_full_or_not_at_all
      case type
        when :principal
          if amount < loan.principal_due_on(received_on) and amount != 0
            return [false, "amount must be paid in full or not at all"]
          else
            return true
          end
        when :interest
          if amount < loan.interest_due_on(received_on) and amount != 0
            return [false, "amount must be paid in full or not at all"]
          else
            return true
          end
      end
    end

    def other_validation
      return true
    end
  end    

  module LoanValidators
  end
end


