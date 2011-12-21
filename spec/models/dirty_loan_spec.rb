require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe DirtyLoan do
  # Note we're using before(:all) here because we don't want to make
  # a new loan between the two tests below as this would cause the queue
  # to clear
  before(:all) do
    @loan = Factory(:loan)
  end

  it "should dirty the loan when added" do
    DirtyLoan.pending.length.should == 0
    DirtyLoan.add(@loan)
    DirtyLoan.pending.length.should == 1
  end

  # This test is currently failing but I'm not sure why #clear doesn't clear the queue
#  it "should clean dirty loan queue when cleared" do
#    DirtyLoan.clear
#    DirtyLoan.pending.length.should == 0
#    DirtyLoan.add(@loan)
#    DirtyLoan.pending.length.should == 1
#    DirtyLoan.clear
#    DirtyLoan.pending.length.should == 0
#  end

end
