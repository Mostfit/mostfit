module Mostfit
  module PaymentStyles

    module MargadarshakIGL4_5000
      
      def scheduled_principal_for_installment(number)
        raise ArgumentError if number < 1 or number > actual_number_of_installments
        return 130 if number <= 5
        return 133 if number > 5 and number <= 32
        return 135 if number > 32 and number <= 34
        return 140 if number > 34 and number <= 37
        return 69
      end

      def scheduled_principal_for_installment(number)
        raise ArgumentError if number < 1 or number > actual_number_of_installments
        return 10 if number <= 5
        return 17 if number > 5 and number <= 32
        return 15 if number > 32 and number <= 34
        return 10 if number > 34 and number <= 37
        return 6
      end
    end
  end
end
      
