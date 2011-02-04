require File.join( File.dirname(__FILE__), '..', "spec_helper" )
describe Report do
  before(:all) do 
    @date = Date.new(2009, 6, 29)
    @weekdays = [:monday,:tuesday,:wednesday,:thursday,:friday,:saturday,:sunday]
    @user = User.new(:login => 'Joe', :password => 'password', :password_confirmation => 'password', :role => :admin)
    @user.save
    @user.should be_valid
    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.should be_valid
    @manager.save
    @funder = Funder.new(:name => "FWWB")
    @funder.save
    @funder.should be_valid
    
    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", 
                                    :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.save
    @funding_line.should be_valid
    @num_clients = []
    @loans = []
    @loan_product = LoanProduct.new
    @loan_product.name = "LP1"
    @loan_product.max_amount = 10000
    @loan_product.min_amount = 1000
    @loan_product.max_interest_rate = 100
    @loan_product.min_interest_rate = 0.1
    @loan_product.installment_frequency = :weekly
    @loan_product.max_number_of_installments = 50
    @loan_product.min_number_of_installments = 25
    @loan_product.loan_type = "DefaultLoan"
    @loan_product.valid_from = Date.parse('2000-01-01')
    @loan_product.valid_upto = Date.parse('2012-01-01')
    @loan_product.save
    @loan_product.errors.each {|e| puts e}
    @loan_product.should be_valid

    @target_for_number = Target.new(:attached_to => :staff_member, :type => :client_registration, :attached_id => @manager.id, :start_value => 100,
                                    :target_value => 1000, :created_at => Date.today, :start_date => Date.new(Date.today.year, Date.today.month, 01),
                                    :deadline => Date.new(Date.today.year, Date.today.month, -1))
    @target_for_number.save
    @target_for_number.errors.each {|e| puts e}
    @target_for_number.should be_valid

    @target_for_amount = Target.new(:attached_to => :staff_member, :type => :loan_disbursement_by_amount, :attached_id => @manager.id,
                                    :target_value => 10_00_000, :created_at => Date.today, :start_value => 10_000,
                                    :start_date => Date.new(Date.today.year, Date.today.month, 01),
                                    :deadline => Date.new(Date.today.year, Date.today.month, -1))
    @target_for_amount.save!
    @target_for_amount.errors.each {|e| puts e}
    @target_for_amount.should be_valid

    @region = Region.new(:id => 1, :name => "Region 1", :manager_id => @manager.id, :creation_date => Date.today)
    @region.save
    @region.errors.each {|e| puts e}
    @region.should be_valid

    @area = Area.new(:name => "Area 1", :region_id => @region.id, :manager_id => @manager.id, :creation_date => Date.today)
    @area.save
    @area.errors.each {|e| puts e}
    @area.should be_valid
    
      # generate a couple of branches
    if Loan.all.count == 0
      Merb.logger.info "Generating data"
      ["br1","br2"].each do |b|
        Merb.logger.info "\t generating branch"
        branch = instance_variable_set("@#{b}",Branch.new(:name => b))
        branch.manager = @manager
        branch.area_id = @area.id
        branch.code = b
        branch.save
        branch.should be_valid
        # and seven centres in each, one for each day
        [:monday, :tuesday].each_with_index do |day,cwday|                               
          center = instance_variable_set("@#{b}_#{day}",Center.new(:name => day.to_s))
          center.manager = @manager
          center.branch = branch
          center.meeting_day = day
          center.code = day
          center.save
          center.errors.each {|e| puts e}
          center.should be_valid
          # make three clients
          num_clients = 3
          # give each one a loan of amount between 10K and 20K in multiples of 10
          (1..num_clients).each do |cl|
            Merb.logger.info "#{b}_#{day}_#{cl}"
            client = instance_variable_set("@#{b}_#{day}_#{cl}", Client.new(:name => 'Ms C.L. Ient', :reference => "#{b}_#{day}_#{cl}"))
            client.center  = center
            client.created_by = @user
            client.client_type = ClientType.first||ClientType.create(:type => "standard")
            client.date_joined = @date - 1
            client.save
            client.errors.each {|e| puts e}
            client.should be_valid
            loan = instance_variable_set("@#{b}_#{day}_#{cl}_l", Loan.new)
            loan.amount = cl * 1000 # loans total in each branch is (7*8)/2 * 1000 = 28,000
            # how should they be disbursed? randomly? something more elegant? 1 in each week?
            # which is the first day?
            # next meeting day of course
            loan.scheduled_disbursal_date = @date+cwday
            loan.disbursal_date = loan.scheduled_disbursal_date
            loan.disbursed_by = @manager
            loan.scheduled_first_payment_date = loan.scheduled_disbursal_date + 7
            loan.interest_rate = 0.1
            loan.installment_frequency = :weekly
            loan.number_of_installments = 50
            loan.applied_on = @date
            loan.applied_by = @manager
            loan.approved_on = loan.applied_on
            loan.approved_by = @manager
            loan.funding_line = @funding_line
            loan.client = client
            loan.loan_product = @loan_product
            loan.history_disabled = true
            loan.save
            loan.errors.each  {|e| puts e}
            loan.should be_valid
          end
        end
      end
    end
    Loan.all.each{|l| l.update_history}
  end
  
  it "should have 2 * 6 centers and centers * 3 clients" do
    Center.all.count.should == 2 * 2
    Client.all.count.should == 2 * 2 * 3
    Loan.all.count.should == 2 * 2 * 3
  end

  
  it "should have proper statistics after first monday's payments" do
    Merb.logger.info "checking statistics after first payment"
    @date = Loan.all.min(:scheduled_first_payment_date)
    @repaying_loans = Loan.all(:scheduled_first_payment_date => @date)
    @repaying_loans.count.should be == 2 * 3
    @repaying_loans.each_with_index do |l,i|
      l.history_disabled = true
      # we know that the amount to be repaid is correct because of the tests on each individual loan type.
      # we also know that the outstanding balance etc are all kosher for the same reason
      # no need to repeat them here.
      amt = [l.scheduled_principal_for_installment(1),l.scheduled_interest_for_installment(1)]
      success, prin, int, fee = l.repay(amt, @user, @date, @manager)      
      success.should be_true
      prin.should be_true
      int.should be_true
    end
    @repaying_loans.each{|l| l.update_history(true)}
  end

  # now we check the reporting functionality  
  it "should have correct loan count" do
    @date = Loan.all.min(:scheduled_first_payment_date)
    Branch.loan_count(@date).should == {1 => 6, 2 => 6}
  end

  it "should have correct number of clients" do
    @date = Loan.all.min(:scheduled_first_payment_date)
    Branch.client_count(@date).should == {1 => 6, 2 => 6}
    Branch.active_client_count(@date).should == {1 => 6, 2 => 6}
    Branch.dormant_client_count(@date).should == {1 => 0, 2 => 0}
    Branch.client_count_by_loan_cycle(1,@date).should == {1 => 6, 2 => 6}
    #Branch.client_count_by_loan_cycle(2,@date).should == {}
    # add a dummy client and check
    c = Client.new(:center => Center.get(1), :name => "delete me", :reference => "dummy1", :date_joined => "2008-01-01", 
                   :client_type => ClientType.first, :created_by => User.first)
    unless c.save
      p c.errors
    end
    c.should be_valid
    Branch.client_count(@date).should == {1 => 7, 2 => 6}
    Branch.active_client_count(@date).should == {1 => 6, 2 => 6}
    Branch.dormant_client_count(@date).should == {1 => 1, 2 => 0}
  end

  it "should have correct client count event after we add our new loans" do
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
      loan.loan_product = @loan_product
      loan.save
      loan.should be_valid
      loan.errors.each {|e| puts e}
      loan.should be_valid
      total = 0
      (1..loan.number_of_installments).each do |i|
        date = loan.date_for_installment(i)
        _p = loan.scheduled_principal_for_installment(i)
        _i = loan.scheduled_interest_for_installment(i)
        paid = loan.repay([_p,_i], @user, date, @manager, true)        
        paid[1].errors.each {|e| puts e}
        total += _p
      end
      loan.history_disabled = false
      loan.update_history(true)
      loan.get_status(loan.scheduled_maturity_date).should == :repaid
      LoanHistory.all(:loan_id => loan.id).last.actual_outstanding_principal.should == 0
    end
    # TODO get the code working for loan cycles 2 and above
    # Branch.client_count_by_loan_cycle(2,@date).should == {1 => 3, 2=>2}
    Branch.clients_added_between(@date - 10, @date).should == {1=> 6, 2=> 6}
    Branch.clients_added_between('2008-01-02', @date - 2).should == {}
    Branch.clients_added_between('2008-01-01', @date - 2).should == {1 => 1}
    Branch.clients_added_between(@date, '2012-01-01').should == {}
    Client.get(7).destroy
    Branch.clients_deleted_between(Date.today, Date.today + 1).should == {2=>1}
    Branch.clients_deleted_between(Date.today + 1, Date.today + 2).should == {}
  end

  it "should return correct repaid loan count" do
    l = Loan.get(13)
    date = l.payments.last.received_on
    Branch.loans_repaid_between(date-3,  date+3,   "count").should == {1=>5}
    Branch.loans_repaid_between(date+1,  date+100, "count").should == {1=>2}
    Branch.loans_repaid_between(date-100,date-1,   "count").should == {}
  end

  it "should return correct repaid loan amount" do
    l = Loan.get(13)
    date = l.scheduled_maturity_date
    Branch.loans_repaid_between(date - 3, date + 3,   "sum").should == {1=>50000}
    Branch.loans_repaid_between(date+1,   date+100, "sum").should == {1=>20000}
    Branch.loans_repaid_between(date-100, date-1,   "sum").should == {}
  end

  it "should return correct disbursed loan count" do
    l = Loan.get(1)
    date = l.scheduled_disbursal_date

    Branch.loans_disbursed_between(date-3,   date+3,"count").should == {1=>6, 2=>6}
    Branch.loans_disbursed_between(date+1,   date+100,"count").should == {1=>3,2=>3}
    Branch.loans_disbursed_between(date-100, date-1,"count").should == {}
  end

  it "should return correct disbursed loan amount" do
    l = Loan.get(1)
    date = l.scheduled_disbursal_date
    Branch.loans_disbursed_between(date,     date+3,"sum").should == {1=>12000, 2=>12000}
    Branch.loans_disbursed_between(date+1,   date+100,"sum").should == {1=>6000, 2=>6000}
    Branch.loans_disbursed_between(date-100, date-1,"sum").should == {}
  end

  it "should give correct principal due" do
    l = Loan.get 1
    date = l.scheduled_first_payment_date
    Branch.principal_due_between(date,     date + 6).should == {1=> 120, 2=> 120}
    Branch.principal_due_between(date+7,   date + 13).should == {1=> 120, 2=> 120}
    Branch.principal_due_between(date,     date + 13).should == {1=> 360, 2=> 360}
  end

  it "should give correct principal received" do
    l = Loan.get 1
    date = l.scheduled_first_payment_date
    Branch.principal_received_between(date + 7, date + 13).should == {}
    Branch.principal_received_between(date-1,     date + 6).should == {1=>(20 + 40 + 60), 2=>(40 + 60)}
  end

  it "should give correct interest due" do
    l = Loan.get 1
    date = l.scheduled_first_payment_date
    loans =  Loan.all
    Branch.interest_due_between(date, date + 6).should == {1=> 12, 2=> 12}
    Branch.interest_due_between(date + 7, date + 13).should == {1=> 12, 2=> 12}
  end

  it "should give correct interest received" do
    l = Loan.get 1
    date = l.scheduled_first_payment_date
    Branch.interest_received_between(date + 7, date + 13).should == {}
    Branch.interest_received_between(date,     date + 6).should == {1 => (2 + 4 + 6), 2 => (4 + 6)}
  end

  it "should give correct principal outstanding" do
    #TODO check the "repaid" loans as well
    l = Loan.get 1
    date = l.scheduled_first_payment_date - 1
    Branch.principal_outstanding(date).should == {1 => 12000, 2 => 12000}
    date = date + 2
    Branch.principal_outstanding(date).should == {1 => 11880, 2 => 11880}
    date = date + 15
    Branch.principal_outstanding(date).should == {1 => 11880, 2 => 11880}
  end

  it "should give correct scheduled principal outstanding" do
    #TODO check the "repaid" loans as well
    l = Loan.get 1
    date = l.scheduled_first_payment_date
    Branch.scheduled_principal_outstanding(date - 1).should == {1 => 12000, 2 => 12000}
    Branch.scheduled_principal_outstanding(date).should == {1 => 12000 - (20 + 40 + 60),  2 => 12000 - (20 + 40 + 60)}
    Branch.scheduled_principal_outstanding(date+1).should == {1 => 12000 - 2*(20 + 40 + 60),  2 => 12000 - 2*(20 + 40 + 60)}
    Branch.scheduled_principal_outstanding(date + 8).should == {1 => 12000 - 2*(40 + 80 + 120), 2 => 12000 - 2*(40 + 80 + 120)}
  end


  it "should give correct total outstanding" do
    #TODO check the "repaid" loans as well
    l = Loan.get 1
    date = l.scheduled_first_payment_date
    Branch.total_outstanding(date - 1).should == {1 => 13200, 2 => 13200}
    Branch.total_outstanding(date).should == {1 => 13200 - (22 + 44 + 66), 2 => 13200 - (22 + 44 + 66)}
    Branch.total_outstanding(date + 10).should == {1 => 13200 - (22 + 44 + 66), 2 => 13200 - (22 + 44 + 66)}
  end


  it "should give correct scheduled total outstanding" do
    #TODO check the "repaid" loans as well
    l = Loan.get 1
    date = l.scheduled_first_payment_date
    Branch.scheduled_total_outstanding(date - 1).should == {1 => 13200, 2 => 13200}
    Branch.scheduled_total_outstanding(date).should == {1 => 13200 - (22 + 44 + 66), 2 => 13200 - (22 + 44 + 66)}
    Branch.scheduled_total_outstanding(date + 15).should == {1 => 13200 - 3*(44 + 88 + 132), 2 => 13200 - 3*(44 + 88 + 132)}
  end  

  #specs for branch target reports.
  it "should give correct disbursal loan count,amount,overdue,sanctioned, total and variance" do
    l = Loan.get 1
    date = l.scheduled_disbursal_date
    report = StaffTargetReport.new({:branch_id => l.client.center.branch.id}, {:to_date => date}, User.first)
    data    = report.generate
    loan_overdue = Loan.all(:scheduled_disbursal_date.lte => date, :approved_on.lte => date, :disbursal_date => nil,
                            :applied_by => @manager, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i
    loan_sanctioned = Loan.all(:approved_on.not => nil, :approved_by => @manager, :scheduled_disbursal_date.lte => date, :disbursal_date => nil,
                                 :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i
    total_loan = ((loan_overdue || 0) + loan_sanctioned)
    loan_count_till_date = Loan.count(:disbursed_by => @manager, :disbursal_date.gte => Date.new(date.year, date.month, 01),
                                      :disbursal_date.lte => date, :rejected_on => nil, :written_off_on => nil)
    loan_amount_till_date = Loan.all(:disbursed_by => @manager, :disbursal_date.gte => Date.new(date.year, date.month, 01),
                                     :disbursal_date.lte => date, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum)
    disbursed_loan = Loan.all(:approved_on.lte => date, :scheduled_disbursal_date.lte => date, :disbursed_by => @manager,
                              :disbursal_date => date, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i

    data[@manager.name][:disbursement][:till_date][0].should == loan_count_till_date
    data[@manager.name][:disbursement][:till_date][1].should == loan_amount_till_date
    data[@manager.name][:disbursement][:today][:overdue].should == (loan_overdue || 0)
    data[@manager.name][:disbursement][:today][:sanctioned].should == loan_sanctioned
    data[@manager.name][:disbursement][:today][:disbursed].should == disbursed_loan
    data[@manager.name][:disbursement][:today][:total].should == ((loan_overdue || 0) + loan_sanctioned)
    data[@manager.name][:disbursement][:today][:variance_from_sanctioned].should == (total_loan - disbursed_loan).abs
  end

  it "should show correct loan overdue disbursals" do
    l = Loan.get 1
    date = l.scheduled_disbursal_date
    l.disbursal_date = nil
    l.disbursed_by = nil
    l.save
    report = StaffTargetReport.new({:area_id => @manager.centers.branches.areas[0].id}, {:to_date => date}, User.first)
    data   = report.generate
    
    data[@manager.name][:disbursement][:today][:overdue].should == l.amount
  end
  
  it "should give correct repayments and loan overdue" do
    l = Loan.get 1
    date = l.scheduled_first_payment_date
    branch_id = @manager.centers.branches.first.id
    report = StaffTargetReport.new({:branch_id => branch_id}, {:to_date => date}, User.first)
    data   = report.generate
    @center = Center.all(:branch_id => branch_id)
    outstandings_today  = LoanHistory.sum_outstanding_grouped_by(date, :center, {:center_id => @center.map{|c| c.id}})
    center_ids = @center.map{|c| c.id}
    outstanding = outstandings_today.find_all{|row| center_ids.include?(row.center_id)}.map{|x| x[0].to_i}.reduce(0){|s,x| s+=x}
    actual_payment = Payment.all(:received_by => @manager, :received_on => date).sum(:amount)
    variance = outstanding - (actual_payment || 0)
    overdue_repayment = LoanHistory.defaulted_loan_info_for(@manager, date, nil, :aggregate, :managed).principal_due.to_i

    data[@manager.name][:repayment][:actual].should == (actual_payment || 0)
    data[@manager.name][:repayment][:var].should == overdue_repayment
    data[@manager.name][:repayment][:due].should == outstanding
    data[@manager.name][:repayment][:total_variance].should == (variance).abs
    data[@manager.name][:repayment][:variance_till_date].should == (overdue_repayment + variance).abs
  end

  it "should give correct outstanding loan amount" do
    l = Loan.get 1
    date = l.scheduled_disbursal_date
    report = StaffTargetReport.new({:branch_id => l.client.center.branch_id}, {:to_date => date}, User.first)
    data = report.generate
    amount_outstanding, total_outstanding = {}, {}
    amount_outstanding[@manager] = LoanHistory.sum_outstanding_for(@manager, date, :managed)
    if amount_outstanding[@manager] != false
      total_outstanding[@manager] = amount_outstanding[@manager][0].actual_outstanding_principal.to_i
    else
      total_outstanding[@manager] = 0
    end

    data[@manager.name][:total_outstanding].should == total_outstanding[@manager]
  end

  it "should give correct actual and target client count" do
    date = @date
    report = StaffTargetReport.new({:branch_id => @manager.centers.branches.map{|b| b.id}.uniq[0]}, {:to_date => date}, User.first)
    data = report.generate
    actual_client_created_date      = Client.all(:date_joined => date, :created_by_staff_member_id => @manager.id).count
    actual_client_created_till_date = Client.all(:date_joined.gte => Date.new(date.year, date.month, 1), :date_joined.lte => date,
                                                 :created_by_staff_member_id => @manager.id).count

    data[@manager.name][:development][:actual][0].should == actual_client_created_date
    data[@manager.name][:development][:actual][1].should == actual_client_created_till_date
  end

  it "should give correct targets for the month and the variance" do
    date = Date.today
    report = StaffTargetReport.new({:branch_id => @manager.centers.branches.map{|b| b.id}.uniq[0]}, {:to_date => date}, User.first)
    data = report.generate
    staff_members = {}
    target_amount, target_number = Hash.new(0), Hash.new(0)
    Target.all(:attached_to => :staff_member, :type => :loan_disbursement_by_amount, :attached_id => @manager.id,
               :created_at.lte => date, :deadline.gte => Date.new(date.year, date.month, 01), 
               :deadline.lte => Date.new(date.year, date.month, -1)).group_by{|t| t.attached_id}.each{|staff_id, targets|
      target_amount[staff_id] ||= 0
      target_amount[staff_id] += targets.map{|t| (t.target_value - t.start_value)}.reduce(0){|s,x| s+=x} if targets
    }
    
    Target.all(:attached_to => :staff_member, :type => :client_registration, :attached_id => @manager.id,
                   :created_at.lte => date, :deadline.gte =>  Date.new(date.year, date.month, 01),
                   :deadline.lte => Date.new(date.year, date.month, -1)).group_by{|t| t.attached_id}.each{|staff_id, targets|
      target_number[staff_id] ||= 0
      target_number[staff_id] += targets.map{|t| (t.target_value - t.start_value)}.reduce(0){|s,x| s+=x} if targets
    }

    actual_client_created_till_date = Client.all(:date_joined.gte => Date.new(date.year, date.month, 01), :date_joined.lte => date,
                                                 :created_by_staff_member_id => @manager.id).count
    target_variance = (target_number.values[0]) - actual_client_created_till_date
    loan_amount_till_date = Loan.all(:disbursed_by => @manager, :disbursal_date.gte => Date.new(date.year, date.month, 01),
                                     :disbursal_date.lte => date, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum)
    disbursed_loan = Loan.all(:approved_on.lte => date, :scheduled_disbursal_date.lte => date, :disbursed_by => @manager,
                              :disbursal_date => date, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i

    data[@manager.name][:development][:target][0].should == target_number.values[0]
    data[@manager.name][:disbursement][:target][0].should == target_amount.values[0]
    data[@manager.name][:development][:variance].should == (target_variance).abs
    data[@manager.name][:disbursement][:today][:variance_from_target].should == (target_amount.values[0] - (loan_amount_till_date || 0) - disbursed_loan).abs
  end

  #specs for Area Target Report.

  it "should give correct disbursal loan count,amount,overdue,sanctioned, total and variance" do
    l = Loan.get 1
    date = l.scheduled_disbursal_date
    report = StaffTargetReport.new({:area_id => l.client.center.branch.area_id}, {:to_date => date}, User.first)
    data   = report.generate
    loan_overdue = Loan.all(:scheduled_disbursal_date.lte => date, :approved_on.lte => date, :disbursal_date => nil,
                            :applied_by => @manager, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i
    loan_sanctioned = Loan.all(:approved_on.not => nil, :approved_by => @manager, :scheduled_disbursal_date.lte => date, :disbursal_date => nil,
                               :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i
    total_loan = ((loan_overdue || 0) + loan_sanctioned)
    loan_count_till_date = Loan.count(:disbursed_by => @manager, :disbursal_date.gte => Date.new(date.year, date.month, 01),
                                      :disbursal_date.lte => date, :rejected_on => nil, :written_off_on => nil)
    loan_amount_till_date = Loan.all(:disbursed_by => @manager, :disbursal_date.gte => Date.new(date.year, date.month, 01),
                                     :disbursal_date.lte => date, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum)
    disbursed_loan = Loan.all(:approved_on.lte => date, :scheduled_disbursal_date.lte => date, :disbursed_by => @manager,
                              :disbursal_date => date, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i

    data[@manager.name][:disbursement][:till_date][0].should == loan_count_till_date
    data[@manager.name][:disbursement][:till_date][1].should == loan_amount_till_date
    data[@manager.name][:disbursement][:today][:overdue].should == (loan_overdue || 0)
    data[@manager.name][:disbursement][:today][:sanctioned].should == loan_sanctioned
    data[@manager.name][:disbursement][:today][:disbursed].should == disbursed_loan
    data[@manager.name][:disbursement][:today][:total].should == ((loan_overdue || 0) + loan_sanctioned)
    data[@manager.name][:disbursement][:today][:variance_from_sanctioned].should == (total_loan - disbursed_loan).abs
  end

  it "should show correct loan overdue disbursals" do
    l = Loan.get 1
    date = l.scheduled_disbursal_date
    l.disbursal_date = nil
    l.disbursed_by = nil
    l.save
    report = StaffTargetReport.new({:area_id => l.client.center.branch.area_id}, {:to_date => date}, User.first)
    data   = report.generate

    data[@manager.name][:disbursement][:today][:overdue].should == l.amount
  end

  it "should give correct repayments and loan overdue" do
    l = Loan.get 1
    date = l.scheduled_first_payment_date
    report = StaffTargetReport.new({:area_id => l.client.center.branch.area_id}, {:to_date => date}, User.first)
    data   = report.generate
    @center = Center.all
    outstandings_today  = LoanHistory.sum_outstanding_grouped_by(date, :center, {:center_id => @center.map{|c| c.id}})
    center_ids = @center.map{|c| c.id}
    outstanding = outstandings_today.find_all{|row| center_ids.include?(row.center_id)}.map{|x| x[0].to_i}.reduce(0){|s,x| s+=x}
    actual_payment = Payment.all(:received_on => date).sum(:amount)
    variance = outstanding - (actual_payment || 0)
    overdue_repayment = LoanHistory.defaulted_loan_info_for(@manager, date, nil, :aggregate, :managed).principal_due.to_i

    data[@manager.name][:repayment][:actual].should == (actual_payment || 0)
    data[@manager.name][:repayment][:var].should == overdue_repayment
    data[@manager.name][:repayment][:due].should == outstanding
    data[@manager.name][:repayment][:total_variance].should == (variance).abs
    data[@manager.name][:repayment][:variance_till_date].should == (overdue_repayment + variance).abs
  end

  it "should give correct outstanding loan amount" do
    l = Loan.get 1
    date = l.scheduled_disbursal_date
    report = StaffTargetReport.new({:area_id => l.client.center.branch.area_id}, {:to_date => date}, User.first)
    data = report.generate
    amount_outstanding, total_outstanding = {}, {}
    amount_outstanding[@manager] = LoanHistory.sum_outstanding_for(@manager, date, :managed)
    if amount_outstanding[@manager] != false
      total_outstanding[@manager] = amount_outstanding[@manager][0].actual_outstanding_principal.to_i
    else
      total_outstanding[@manager] = 0
    end

    data[@manager.name][:total_outstanding].should == total_outstanding[@manager]
  end

  it "should give correct actual and target client count" do
    date = @date
    report = StaffTargetReport.new({:area_id => @manager.centers.branches.areas.map{|a| a.id}[0]}, {:to_date => date}, User.first)
    data = report.generate
    actual_client_created_date      = Client.all(:date_joined => date, :created_by_staff_member_id => @manager.id).count
    actual_client_created_till_date = Client.all(:date_joined.gte => Date.new(date.year, date.month, 1), :date_joined.lte => date,
                                                 :created_by_staff_member_id => @manager.id).count

    data[@manager.name][:development][:actual][0].should == actual_client_created_date
    data[@manager.name][:development][:actual][1].should == actual_client_created_till_date
  end

  it "should give correct targets for the month and the variance" do
    date = Date.today
    report = StaffTargetReport.new({:area_id => @manager.centers.branches.areas.map{|a| a.id}[0]}, {:to_date => date}, User.first)
    data = report.generate
    staff_members = {}
    target_amount, target_number = Hash.new(0), Hash.new(0)
    Target.all(:attached_to => :staff_member, :type => :loan_disbursement_by_amount, :attached_id => @manager.id,
               :created_at.lte => date, :deadline.gte => Date.new(date.year, date.month, 01),
               :deadline.lte => Date.new(date.year, date.month, -1)).group_by{|t| t.attached_id}.each{|staff_id, targets|
      target_amount[staff_id] ||= 0
      target_amount[staff_id] += targets.map{|t| (t.target_value - t.start_value)}.reduce(0){|s,x| s+=x} if targets
    }

    Target.all(:attached_to => :staff_member, :type => :client_registration, :attached_id => @manager.id,
               :created_at.lte => date, :deadline.gte => Date.new(date.year, date.month, 01),
               :deadline.lte => Date.new(date.year, date.month, -1)).group_by{|t| t.attached_id}.each{|staff_id, targets|
      target_number[staff_id] ||= 0
      target_number[staff_id] += targets.map{|t| (t.target_value - t.start_value)}.reduce(0){|s,x| s+=x} if targets
    }

    actual_client_created_till_date = Client.all(:date_joined.gte => Date.new(date.year, date.month, 01), :date_joined.lte => date,
                                                 :created_by_staff_member_id => @manager.id).count
    target_variance = (target_number.values[0]) - actual_client_created_till_date
    loan_amount_till_date = Loan.all(:disbursed_by => @manager, :disbursal_date.gte => Date.new(date.year, date.month, 01),
                                     :disbursal_date.lte => date, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum)
    disbursed_loan = Loan.all(:approved_on.lte => date, :scheduled_disbursal_date.lte => date, :disbursed_by => @manager,
                              :disbursal_date => date, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i

    data[@manager.name][:development][:target][0].should == target_number.values[0]
    data[@manager.name][:disbursement][:target][0].should == target_amount.values[0]
    data[@manager.name][:development][:variance].should == (target_variance).abs
    data[@manager.name][:disbursement][:today][:variance_from_target].should == (target_amount.values[0] - (loan_amount_till_date || 0) - disbursed_loan).abs
  end
end
