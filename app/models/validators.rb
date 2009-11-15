module Misfit
  module PaymentValidators
    def test_validation
      puts "test_validation"
      [false, "test validator failed"]
    end

    def other_validation
      puts "other_validation"
      [false, "other_val"]
    end
  end    
end
