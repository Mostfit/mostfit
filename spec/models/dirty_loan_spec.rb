require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe DirtyLoan do
  before(:all) do
    load_fixtures :staff_members, :branches, :centers, :client_types, :clients, :funders, :funding_lines, :loan_products, :loans
  end

  it "should dirty the loan when added" do
    loan = Loan.first
    DirtyLoan.pending.length.should == 0
    DirtyLoan.add(loan)
    DirtyLoan.pending.length.should == 1
  end

  it "should clean dirty loan queue when cleared" do
    loan = Loan.first
    DirtyLoan.clear
    DirtyLoan.pending.length.should == 0
    DirtyLoan.add(loan)
    DirtyLoan.pending.length.should == 1
    DirtyLoan.clear
    DirtyLoan.pending.length.should == 0
  end

end
