require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a report exists" do
  Report.all.destroy!
end

given "an admin user exist" do
  load_fixtures :users
  response = request url(:perform_login), :method => "PUT", :params => { :login => 'admin', :password => 'password' }
  response.should redirect
end

describe "/reports", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports")
    end

    it "responds successfully" do
      @response.should be_successful
    end

    #Periodic reports                                                                                                                           
    it "should have daily report" do
      pending
      @response.should have_xpath("//ul/li")
    end

    it "should have Weekly Report" do
      pending
      @response.should have_xpath("//ul/li[2]")
    end

    #Consolidated reports
    it "should have Consolidated Report (center wise)" do
      pending
      @response.should have_xpath("//ul[2]/li")
    end

    it "should have Group Wise Consolidated Report" do
      pending
      @response.should have_xpath("//ul[2]/li[2]")
    end

    it "should have Consolidated Report for Staff" do
      pending
      @response.should have_xpath("//ul[2]/li[3]")
    end

    it "should have Quarter Wise Consolidated Report" do
      pending
      @response.should have_xpath("//ul[2]/li[4]")
    end

    it "should have Aggregate Consolodated Report" do
      pending
      @response.should have_xpath("//ul[2]/li[5]")
    end

    #Registers
    it "should have Transaction Ledger" do
      pending
      @response.should have_xpath("//ul[3]/li")
    end

    it "should have Loan Sanction Register" do
      pending
      @response.should have_xpath("//ul[3]/li[2]")
    end

    it "should have Loan Disbursement Register" do
      pending
      @response.should have_xpath("//ul[3]/li[3]")
    end

    it "should have Loan Scheduled Disbursement Register" do
      pending
      @response.should have_xpath("//ul[3]/li[4]")
    end

    it "should have Claim Report" do
      pending
      @response.should have_xpath("//ul[3]/li[5]")
    end

    #Targets and Projections
    it "should have Cash Projection Report" do
      pending
      @response.should have_xpath("//ul[4]/li")
    end

    it "should have Target Vs Performance Report" do
      pending
      @response.should have_xpath("//ul[4]/li[2]")
    end

    it "should have Staff Target Report" do
      pending
      @response.should have_xpath("//ul[4]/li[3]")
    end

    it "should have Incentive Report" do
      pending
      @response.should have_xpath("//ul[4]/li[4]")
    end

    #Statistics
    it "should have Average Loan Size Report" do
      pending
      @response.should have_xpath("//ul[5]/li")
    end

    it "should have Loan Purpose Report" do
      pending
      @reponse.should have_xpath("//ul[5]/li[2]")
    end

    it "should have CLient Occupation Report" do
      pending
      @response.should have_xpath("//ul[5]/li[3]")
    end

    it "should have Loan Closed Report" do
      pending
      @response.should have_xpath("//ul[5]/li[4]")
    end

    #Exceptions
    it "should have Repayment Overdue Register" do
      pending
      @reponse.should have_xpath("//ul[6]/li")
    end

    it "should have Late Disbursals Report" do
      pending
      @response.should have_xpath("//ul[6]/li[2]")
    end

    it "should have Deliquent Loan Report" do
      pending
      @response.should have_xpath("//ul[6]/[3]")
    end

    it "should have PAR Report" do
      pending
      @response.should have_xpath("//ul[6]/li[4]")
    end

    it "should have Client Absenteeism Report" do
      pending
      @response.should have_xpath("//ul[6]/li[5]")
    end

    it "should have Duplicate Client Report" do
      pending
      @response.should have_xpath("//ul[6]/li[6]")
    end

    it "should have Non Disbursed Clients after GRT" do
      pending
      @response.should have_xpath("//ul[6]/li[7]")
    end

    #Accounting
    it "should have General Ledger" do
      pending
      @response.should have_xpath("//ul[7]/li")
    end

    it "should have Trial Balance" do
      pending
      @response.should have_xpath("//ul[7]/li[2]")
    end

    #Custom Reports
    it "should have Custom Reports" do
      pending
      @response.should have_xpath("//ul[8]/li")
    end
  end
end
  
#Periodic reports
describe "/reports/DailyReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/DailyReport")
    end
    
    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/WeeklyReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/WeeklyReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

#Consolidated Reports
describe "/reports/ConsolidatedReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/ConsolidatedReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/GroupConsolidatedReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/GroupConsolidatedReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/StaffConsolidatedReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/StaffConsolidatedReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/QuarterConsolidatedReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/QuarterConsolidatedReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/AggregateConsolidatedReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/AggregateConsolidatedReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

#Registers
describe "/reports/TransactionLedger", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/TransactionLedger")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/LoanSanctionRegister", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/LoanSanctionRegister")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/LoanDisbursementRegister", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/LoanDisbursementRegister")
    end
    
    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/ScheduledDisbursementRegister", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/ScheduledDisbursementRegister")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/ClaimReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/ClaimReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

#Targets and Projections
describe "/reports/ProjectedReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/ProjectedReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/TargetReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/TargetReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/StaffTargetReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/StaffTargetReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/IncentiveReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/IncentiveReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

#Statistics
describe "/reports/LoanSizePerManagerReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/LoanSizePerManagerReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/LoanPurposeReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/LoanPurposeReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/ClientOccupationReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/ClientOccupationReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/ClosedLoanReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/ClosedLoanReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

#Exceptions
describe "/reports/RepaymentOverdue", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/RepaymentOverdue")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/LateDisbursalsReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/LateDisbursalsReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/DelinquentLoanReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/DelinquentLoanReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/ParByCenterReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/ParByCenterReport")
    end
    
    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/ClientAbsenteeismReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/ClientAbsenteeismReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/DuplicateClientsReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/DuplicateClientsReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/NonDisbursedClientsAfterGroupRecognitionTest", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/NonDisbursedClientsAfterGroupRecognitionTest")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

#Accounting
describe "/reports/GeneralLedgerReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/GeneralLedgerReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

describe "/reports/TrialBalanceReport", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/reports/TrialBalanceReport")
    end

    it "responds successfully" do
      @response.should be_successful
    end
  end
end

#Custom Reports
describe "/bookmarks", :given => "an admin user exist" do
  describe "GET" do
    before(:each) do
      @response = request("/bookmarks")
    end
    
    it "responds successfully" do
      @response.should be_successful
    end
  end
end

# describe "resource(:reports)" do
#   describe "GET" do
    
#     before(:each) do
#       @response = request(resource(:reports))
#     end
    
#     it "responds successfully" do
#       @response.should be_successful
#     end

#     it "contains a list of reports" do
#       pending
#       @response.should have_xpath("//ul")
#     end
    
#   end
  
#   describe "GET", :given => "a report exists" do
#     before(:each) do
#       @response = request(resource(:reports))
#     end
    
#     it "has a list of reports" do
#       pending
#       @response.should have_xpath("//ul/li")
#     end
#   end
  
#   describe "a successful POST" do
#     before(:each) do
#       Report.all.destroy!
#       @response = request(resource(:reports), :method => "POST", 
#         :params => { :report => { :id => nil }})
#     end
    
#     it "redirects to resource(:reports)" do
#       @response.should redirect_to(resource(Report.first), :message => {:notice => "report was successfully created"})
#     end
    
#   end
# end

# describe "resource(@report)" do 
#   describe "a successful DELETE", :given => "a report exists" do
#      before(:each) do
#        @response = request(resource(Report.first), :method => "DELETE")
#      end

#      it "should redirect to the index action" do
#        @response.should redirect_to(resource(:reports))
#      end

#    end
# end

# describe "resource(:reports, :new)" do
#   before(:each) do
#     @response = request(resource(:reports, :new))
#   end
  
#   it "responds successfully" do
#     @response.should be_successful
#   end
# end

# describe "resource(@report, :edit)", :given => "a report exists" do
#   before(:each) do
#     @response = request(resource(Report.first, :edit))
#   end
  
#   it "responds successfully" do
#     @response.should be_successful
#   end
# end

# describe "resource(@report)", :given => "a report exists" do
  
#   describe "GET" do
#     before(:each) do
#       @response = request(resource(Report.first))
#     end
  
#     it "responds successfully" do
#       @response.should be_successful
#     end
#   end
  
#   describe "PUT" do
#     before(:each) do
#       @report = Report.first
#       @response = request(resource(@report), :method => "PUT", 
#         :params => { :report => {:id => @report.id} })
#     end
  
#     it "redirect to the report show action" do
#       @response.should redirect_to(resource(@report))
#     end
#   end
  
# end

