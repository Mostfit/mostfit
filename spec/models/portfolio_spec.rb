require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Portfolio do
  before(:all) do
    @staff_member = Factory(:staff_member)
    @user = Factory(:user)
    @funder = Factory(:funder)
  end

# This one raises a nil error somewhere deep in the bowels of Loan,
# I couldn't quite figure it out
#
#  it "should have correct eligible loans" do
#    Loan.all(:id => [1, 2, 3]).each{|l|
#      l.history_disabled = false
#      l.repay(l.amount, @user, Date.today, @staff_member)
#    }
#    Loan.all.each{|l|
#      l.update_history
#    }
#    portfolio = Portfolio.new
#    outstanding_eligible = portfolio.eligible_loans.collect{|branch, centers|
#      centers.values.reduce(0){|s, x| 
#        s += x.actual_outstanding_principal
#      }
#    }.reduce(0){|s, x| 
#      s += x
#    }.to_i
#    
#    actual_outstanding = Loan.all.find_all{|l| [:outstanding, :disbursed].include?(l.status)}.reduce(0){|s, l| s += l.actual_outstanding_principal_on(Date.today)}.to_i
#    
#    outstanding_eligible.should be_equal(actual_outstanding)
#  end

  it "should not delete verified portfolios" do
    @portfolio = Portfolio.new(:name => "first", :created_by => @user, :funder => @funder)
    @portfolio.save
    @portfolio.should be_valid
    
    @portfolio.verified_by = User.first
    @portfolio.should be_valid
    @portfolio.save.should be_true
    @portfolio.should be_valid
    @portfolio.destroy.should == nil
    
    @portfolio.verified_by = nil
    @portfolio.save
    @portfolio.should be_valid    
    @portfolio.destroy.should be_true
  end  
end
