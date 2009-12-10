require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Upload do
  require 'csv'
  include ExcelFormula
  before(:all) do
    @interest     =  0.10
    @amount       = 10000
    @installments = 50
    @data         = []
    CSV.open(File.join(Merb.root, "spec", "fixtures", "pmt.csv"), "r").each{|row|
      @data << row
    }
  end

  it "Should match calculation from excel" do
    balance = @amount
    1.upto(@installments){|installment|
      payment  = pmt(@interest/@installments, @installments, @amount, 0, 0) 
      interest_payable  = balance * @interest / @installments
      principal_payable = payment - interest_payable
      balance           = balance - principal_payable
      
      (principal_payable + interest_payable - payment).should < 0.01
      (principal_payable - @data[installment-1][2].to_f).abs.should < 0.01
      (interest_payable  - @data[installment-1][-1].to_f).abs.should < 0.01
      (payment  - @data[installment-1][-1].to_f - @data[installment-1][-2].to_f).abs.should < 0.01
    }
  end
end
