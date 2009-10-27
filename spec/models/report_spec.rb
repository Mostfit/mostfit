require File.join( File.dirname(__FILE__), '..', "spec_helper" )
@date = Date.today
describe Report do
  before(:all) do 
    @weekdays = [:monday,:tuesday,:wednesday,:thursday,:friday,:saturday,:sunday]
    User.all.destroy!
    StaffMember.all.destroy!
    Funder.all.destroy!
    FundingLine.all.destroy!
    @user = User.new(:id => 234, :login => 'Joey User', :password => 'password', :password_confirmation => 'password')
    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.should be_valid
    @manager.save
    @funder = Funder.new(:name => "FWWB")
    @funder.should be_valid
    
    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.should be_valid
    @num_clients = []
    @loans = []
    
      # generate a couple of branches
    if Loan.all.count == 0
      Merb.logger.info "Generating data"
      ["br1","br2"].each do |b|
        Merb.logger.info "\t generating branch"
        branch = instance_variable_set("@#{b}",Branch.new(:name => b))
        branch.manager = @manager
        branch.should be_valid
        # and seven centres in each, one for each day
        [:monday].each_with_index do |day,cwday|                               
          center = instance_variable_set("@#{b}_#{day}",Center.new(:name => day.to_s))
          center.manager = @manager
          center.branch = branch
          center.meeting_day = day
          center.errors.each {|e| puts e}
          center.should be_valid
          # make three clients
          num_clients = 3
          # give each one a loan of amount between 10K and 20K in multiples of 10
          (1..num_clients).each do |cl|
            Merb.logger.info "#{b}_#{day}_#{cl}"
            client = instance_variable_set("@#{b}_#{day}_#{cl}",Client.new(:name => 'Ms C.L. Ient', :reference => "#{b}_#{day}_#{cl}"))
            client.center  = center
            client.date_joined = Date.today - 1
            client.valid?
            client.errors.each {|e| puts e}
            client.should be_valid
            loan = instance_variable_set("@#{b}_#{day}_#{cl}_l", Loan.new)
            loan.amount = cl * 1000 # loans total in each branch is (7*8)/2 * 1000 = 28,000
            # how should they be disbursed? randomly? something more elegant? 1 in each week?
            # which is the first day?
            # next meeting day of course
            loan.scheduled_disbursal_date = center.next_meeting_date_from(Date.today) + 7
            loan.disbursal_date = loan.scheduled_disbursal_date
            loan.disbursed_by = @manager
            loan.scheduled_first_payment_date = loan.scheduled_disbursal_date + 7
            loan.interest_rate = 0.1
            loan.installment_frequency = :weekly
            loan.number_of_installments = 50
            loan.applied_on = Date.today
            loan.applied_by = @manager
            loan.approved_on = loan.applied_on + 2
            loan.approved_by = @manager
            loan.funding_line = @funding_line
            loan.client = client
            loan.valid?
            loan.errors.each  {|e| puts e}
            loan.should be_valid
#            loan.history_disabled = true
            loan.save
          end
        end
      end
    end
  end
  
  it "should have 2 * 7 centers and centers * 3 clients" do
#    Center.all.count.should == 2 * 7
#    Client.all.count.should == 2 * 7 * 3
  end

  
  it "should have proper statistics after first monday's payments" do
    Merb.logger.info "checking statistics after first payment"
    @date = Loan.all.min(:scheduled_first_payment_date)
    @repaying_loans = Loan.all(:scheduled_first_payment_date => @date)
    @repaying_loans.count.should be == 2 * 3
    @repaying_loans.each_with_index do |l,i|
      # we know that the amount to be repaid is correct because of the tests on each individual loan type.
      # we also know that the outstanding balance etc are all kosher for the same reason
      # no need to repeat them here.
      amt = [l.scheduled_principal_for_installment(1),l.scheduled_interest_for_installment(1)]
      pmt = l.repay(amt, @user, @date, @manager)[1]
      pmt.errors.each {|e| puts e}
      pmt.should be_valid
    end  
  end
    # now we check the reporting functionality
  
  it "should have correct loan count" do
    # @date = Loan.all.min(:scheduled_first_payment_date)
    # Branch.loan_count(@date).should == {1 => 21, 2 => 21}
  end

  it "should have correct number of clients" do
    @date = Loan.all.min(:scheduled_first_payment_date)
    Branch.client_count(@date).should == {1 => 3, 2 => 3}
    Branch.active_client_count(@date).should == {1 => 3, 2 => 3}
    Branch.dormant_client_count(@date).should == {1 => 0, 2 => 0}
    Branch.client_count_by_loan_cycle(1,@date).should == {1 => 3, 2 => 3}
    Branch.client_count_by_loan_cycle(2,@date).should == {}
    # add a dummy client and check
    c = Client.new(:center => Center.get(1), :name => "delete me", :reference => "dummy1", :date_joined => "2008-01-01")
    c.save
    Branch.client_count(@date).should == {1 => 4, 2 => 3}
    Branch.active_client_count(@date).should == {1 => 3, 2 => 3}
    Branch.dormant_client_count(@date).should == {1 => 1, 2 => 0}
    # add a few dummy loans, repay them and check
    (1..5).each do |h|
      c = Client.get(h)
      loan = Loan.new(:amount => 10000)
      loan.client = c
      loan.scheduled_disbursal_date = loan.client.center.next_meeting_date_from(Date.parse('2008-01-01'))
      loan.disbursal_date = loan.scheduled_disbursal_date
      loan.disbursed_by = @manager
      loan.scheduled_first_payment_date = loan.scheduled_disbursal_date + 7
      loan.interest_rate = 0.1
      loan.installment_frequency = :weekly
      loan.number_of_installments = 50
      loan.applied_on = loan.disbursal_date - 20
      loan.applied_by = @manager
      loan.approved_on = loan.applied_on + 2
      loan.approved_by = @manager
      loan.funding_line = @funding_line
      loan.history_disabled = true
      loan.save
      loan.errors.each {|e| puts e}
      loan.should be_valid
      total = 0
      (1..loan.number_of_installments).each do |i|
        date = loan.date_for_installment(i)
        _p = loan.scheduled_principal_for_installment(i)
        _i = loan.scheduled_interest_for_installment(i)
        paid = loan.repay([_p,_i],@user,date,@manager)
        paid[1].errors.inspect if not paid[0]
        total += _p
      end
      loan.history_disabled = false
      loan.update_history
      loan.get_status(loan.scheduled_maturity_date).should == :repaid
      LoanHistory.all(:loan_id => loan.id).last.actual_outstanding_principal.should == 0
    end
    Branch.client_count_by_loan_cycle(2,@date).should == {1 => 3, 2=>2}
    Branch.clients_added_between_such_and_such_date_count(Date.today - 1, Date.today).should == {1=>3,2=>3}
    Branch.clients_added_between_such_and_such_date_count('2008-01-02',Date.today - 2).should == {}
    Branch.clients_added_between_such_and_such_date_count('2008-01-01',Date.today - 2).should == {1 => 1}
    Branch.clients_added_between_such_and_such_date_count(Date.today,'2012-01-01').should == {}
    Client.get(7).destroy
    Branch.clients_deleted_between_such_and_such_date_count(Date.today, Date.today + 1).should == {1=>1}
    Branch.clients_deleted_between_such_and_such_date_count(Date.today + 1, Date.today + 2).should == {}
  end

  it "should return correct repaid loan count" do
    l = Loan.get(7)
    date = l.scheduled_maturity_date
    Branch.loans_repaid_between_such_and_such_date(date-3,date+3,"count").should == {1=>3, 2=>2}
    Branch.loans_repaid_between_such_and_such_date(date+1,date+100,"count").should == {}
    Branch.loans_repaid_between_such_and_such_date(date-100,date-1,"count").should == {}
  end

  it "should return correct repaid loan amount" do
    l = Loan.get(7)
    date = l.scheduled_maturity_date
    Branch.loans_repaid_between_such_and_such_date(date-3,date+3,"sum").should == {1=>30000, 2=>20000}
    Branch.loans_repaid_between_such_and_such_date(date+1,date+100,"sum").should == {}
    Branch.loans_repaid_between_such_and_such_date(date-100,date-1,"sum").should == {}
  end

  it "should return correct disbursed loan count" do
    l = Loan.get(1)
    date = l.scheduled_disbursal_date
    Branch.loans_disbursed_between_such_and_such_date(date-3,date+3,"count").should == {1=>3, 2=>3}
    Branch.loans_disbursed_between_such_and_such_date(date+1,date+100,"count").should == {}
    Branch.loans_disbursed_between_such_and_such_date(date-100,date-1,"count").should == {}
  end

  it "should return correct disbursed loan amount" do
    l = Loan.get(1)
    date = l.scheduled_disbursal_date
    Branch.loans_disbursed_between_such_and_such_date(date,date+3,"sum").should == {1=>6000, 2=>6000}
    Branch.loans_disbursed_between_such_and_such_date(date+1,date+100,"sum").should == {}
    Branch.loans_disbursed_between_such_and_such_date(date-100,date-1,"sum").should == {}
  end

  it "should give correct pricipal due" do
    l = Loan.get 1
    date = l.scheduled_first_payment_date
    Branch.principal_due_between_such_and_such_date(date, date + 6).should == (12000 - 20)
  end
  

  
end





