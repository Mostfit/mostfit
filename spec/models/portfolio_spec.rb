require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Portfolio do
  before(:all) do
    load_fixtures :staff_members, :users, :funders, :funding_lines, :loan_products, :client_types, :branches, :centers, :clients, :loans
  end

  it "should have correct eligible loans" do
    Loan.all(:id => [1, 2, 3]).each{|l|
      l.history_disabled = false
      l.repay(l.amount, User.first, Date.today, StaffMember.first)
    }
    Loan.all.each{|l|
      l.update_history
    }
    portfolio = Portfolio.new
    outstanding_eligible = portfolio.eligible_loans.collect{|branch, centers|
      centers.values.reduce(0){|s, x| 
        s += x.actual_outstanding_principal
      }
    }.reduce(0){|s, x| 
      s += x
    }.to_i
    
    actual_outstanding = Loan.all.find_all{|l| [:outstanding, :disbursed].include?(l.status)}.reduce(0){|s, l| s += l.actual_outstanding_principal_on(Date.today)}.to_i
    
    outstanding_eligible.should be_equal(actual_outstanding)
  end

  it "should not delete verified portfolios" do
    @portfolio = Portfolio.new(:name => "first", :created_by => User.first, :funder => Funder.first)
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
