class EquatedWeeklyRoundedNewInterest < Loan
  # This loan product recalculates interest based on the new balances after rounding.
  include ExcelFormula
  # property :purpose,  String

  def self.display_name
    "Reducing balance schedule with new interest (Equated Weekly)"
  end
  
  def scheduled_principal_for_installment(number)
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > number_of_installments
    return reducing_schedule[number][:principal_payable]
  end

  def scheduled_interest_for_installment(number)  # typically reimplemented in subclasses
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 0 or number > number_of_installments
    return reducing_schedule[number][:interest_payable]
  end
  
private
  def reducing_schedule
    return @reducing_schedule if @reducing_schedule
    @reducing_schedule = {}    
    balance = amount
    payment            = pmt(interest_rate/get_divider, number_of_installments, amount, 0, 0)
    rnd = loan_product.rounding || 1
    actual_payment = (payment / rnd).send(loan_product.rounding_style) * rnd
    1.upto(number_of_installments){|installment|
      @reducing_schedule[installment] = {}
      @reducing_schedule[installment][:interest_payable]  = ((balance * interest_rate) / get_divider)
      @reducing_schedule[installment][:principal_payable] = [(actual_payment - @reducing_schedule[installment][:interest_payable]), balance].min
      balance = balance - @reducing_schedule[installment][:principal_payable]
    }
    return @reducing_schedule
  end
  
  def get_divider
    case installment_frequency
    when :weekly
      52
    when :biweekly
      26
    when :fortnightly
      26
    when :monthly
      12
    when :daily
      365
    end    
  end
end

