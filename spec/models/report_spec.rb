require File.join( File.dirname(__FILE__), '..', "spec_helper" )

#
# This is a rewrite of the old report_spec but it could still use some attention
# We're using this spec not just to test the Report model but also a bunch of
# modules included in various other models, such as Branch. Better separation
# would make this considerably easier to follow.
#
describe Report do

  context "given 2 separate branches with 3 and 2 disbursed loans respectively" do

    before(:each) do
      Loan.all.destroy!
      Branch.all.destroy!
      Center.all.destroy!

      # The factory will automatically create a center & branch for each client
      @client1 = Factory(:client)
      @client2 = Factory(:client)
      @loans = [
        Factory(:disbursed_loan, :client => @client1),
        Factory(:disbursed_loan, :client => @client1),
        Factory(:disbursed_loan, :client => @client1),
        Factory(:disbursed_loan, :client => @client2),
        Factory(:disbursed_loan, :client => @client2)
      ]
    end

    # Branch.loan_count reports the # of current loans for each branch
    it "should report the correct counts through Branch.loan_count" do
      date = @loans.map(&:disbursal_date).min
      Branch.loan_count(date).should eql( { @client1.center.branch.id => 3, @client2.center.branch.id => 2 } )
    end

    # The naming for this test seems off, we're testing some methods on Loan but I don't see tests
    # on any resulting reports?
    it "should have proper statistics for each loan after first payment" do
      @loans.each_with_index do |loan, index|

        amt     = { :principal => loan.scheduled_principal_for_installment(1), :interest => loan.scheduled_interest_for_installment(1) }
        user    = loan.client.created_by
        date    = loan.scheduled_first_payment_date
        manager = loan.client.center.branch.manager

        success, prin, int, fee = loan.repay(amt, user, date, manager)

        success.should be_true
        prin.should be_valid
        int.should be_valid
      end
      # This line was in the original test but didn't seem to test anything, was it setting up a subsequent test?
      @loans.each{ |l| l.update_history(true) }
    end
  end

  #
  # Testing Branch.client_count and it's associates
  #

  context "given a total of 4 clients in 2 centers in different branches" do
    before(:each) do
      Client.all.destroy!
      Branch.all.destroy!
      Loan.all.destroy!
      LoanHistory.all.destroy!

      @center1 = Factory(:center)
      @center2 = Factory(:center)

      @clients = [
        Factory(:client, :center => @center1),
        Factory(:client, :center => @center1),
        Factory(:client, :center => @center1),
        Factory(:client, :center => @center2)
      ]

      # Let's make sure all the clients joined before today
      @clients.each { |c| c.update :date_joined => Date.today - 10 }
    end

    it "should report the correct number of clients for a given date" do
      # If all the clients joined before the given date (today), the first center should count all three
      Branch.client_count(Date.today).should eql( { @center1.branch.id => 3, @center2.branch.id => 1 } )

      # If one of the clients joined after the given date, the first center should only count the first two clients
      @center1.clients.last.update :date_joined => Date.today + 10
      Branch.client_count(Date.today).should eql( { @center1.branch.id => 2, @center2.branch.id => 1 } )
    end

    # Active clients are those with loans that are currently in state :disbursed or :outstanding
    # of which the date_joined was before the given date.
    it "should report the correct number of active clients for a given date" do
      # Since we did not create any loans yet we should get no results
      Branch.active_client_count(Date.today).should eql( {} )

      # We'll create an 'active' loan for two of the clients of center1 and the client of center2
      new_loan1 = Factory(:disbursed_loan, :history_disabled => false, :client => @center1.clients.first)
      new_loan1.update_history
      new_loan2 = Factory(:disbursed_loan, :history_disabled => false, :client => @center1.clients.last)
      new_loan2.update_history
      new_loan3 = Factory(:disbursed_loan, :history_disabled => false, :client => @center2.clients.first)
      new_loan3.update_history

      # The report should now read 2 clients for center1 and 1 client for center2
      Branch.active_client_count(Date.today).should eql( { @center1.branch.id => 2, @center2.branch.id => 1 } )
    end

    # Dormant clients are the inverse of active clients, so all those that do not conform to the rules
    # laid out in the preceding test.
    it "should report the correct number of dormant clients for a given date" do
      # Since we did not create any loans yet we should show all clients as dormant
      Branch.dormant_client_count(Date.today).should eql( { @center1.branch.id => 3, @center2.branch.id => 1 } )

      # We'll create an 'active' loan for two of the clients of center1 and the client of center2
      new_loan1 = Factory(:disbursed_loan, :history_disabled => false, :client => @center1.clients.first)
      new_loan1.update_history
      new_loan2 = Factory(:disbursed_loan, :history_disabled => false, :client => @center1.clients.last)
      new_loan2.update_history
      new_loan3 = Factory(:disbursed_loan, :history_disabled => false, :client => @center2.clients.first)
      new_loan3.update_history

      # The report should read 1 client for center1 and no client for center2
      #
      # Slightly inconsistent with the output of the other client_count methods, see the comments
      # in app/models/reports/branch.rb for details.
      Branch.dormant_client_count(Date.today).should eql( { @center1.branch.id => 1, @center2.branch.id => 0 } )
    end

    it "should report the correct number of borrower clients" do
      # Since we did not create any loans yet we should show all clients as dormant
      Branch.borrower_clients_count(Date.today).should eql( {} )

      # We'll create an 'active' loan for a client of center1
      new_loan1 = Factory(:disbursed_loan, :client => @center1.clients.first)
      # Now branch1 should report one borrower client
      Branch.borrower_clients_count(Date.today).should eql( { @center1.branch.id => 1 } )
    end

    it "should report the correct number of clients by loan cycle" do
      # Since we did not yet create any loans the result should be blank
      Branch.client_count_by_loan_cycle( 1, Date.today ).should eql( {} )

      # We'll create a loan for a client of center1
      new_loan1 = Factory(:disbursed_loan, :client => @center1.clients.first)
      # The new loan will be in the first cycle so the client_count should reflect this:
      Branch.client_count_by_loan_cycle( 1, Date.today ).should eql( { @center1.branch.id => 1 } )

      # We'll create a loan for center2 as well
      new_loan2 = Factory(:disbursed_loan, :client => @center2.clients.first)
      # Now we should have 1 client in cycle 1 for each center/branch
      Branch.client_count_by_loan_cycle( 1, Date.today ).should eql( { @center1.branch.id => 1, @center2.branch.id => 1 } )

      # Not quite sure yet how to increment the loan cycle, so we still need tests for that..
    end

    # Note that clients_added_between dates are inclusive so >= <=
    it "should report correct counts for clients added between certain dates" do
      # We'll arbitrarily set the starting date
      start_date = Date.new( 2011, 12, 01 )

      # Then we'll set the clients join dates at 10 day intervals from then
      @clients.each_with_index { |client, index| client.update :date_joined => start_date + (index * 10) }

      # Then we'll test for valid results
      Branch.clients_added_between(start_date, start_date + 1).should eql({ @center1.branch.id => 1 })
      Branch.clients_added_between(start_date, start_date + 20).should eql({ @center1.branch.id => 3 })
      Branch.clients_added_between(start_date + 20, start_date + 30).should eql({ @center1.branch.id => 1, @center2.branch.id => 1 })
    end

    # Note that clients_deleted_between dates are inclusive so >= <=
    it "should report correct counts for clients deleted between certain dates" do
      deletion_date = Date.new( 2011, 12, 01 )

      # Then we'll set the clients deletion dates at 10 day intervals from then
      @clients.each_with_index { |client, index| client.update :deleted_at => deletion_date + (index * 10) }

      # Then we'll test for valid results
      Branch.clients_deleted_between(deletion_date, deletion_date + 1).should eql({ @center1.branch.id => 1 })
      Branch.clients_deleted_between(deletion_date, deletion_date + 20).should eql({ @center1.branch.id => 3 })
      Branch.clients_deleted_between(deletion_date + 20, deletion_date + 30).should eql({ @center1.branch.id => 1, @center2.branch.id => 1 })
    end
  end
  #
  # Testing Branch.client_count and it's associates
  #

  context "given two branches with 2 and 3 loans respectively" do
    before(:each) do
      # Centers and branches will be created automaticaly by the factory
      @client1 = Factory(:client)
      @client2 = Factory(:client)

      @branch1 = @client1.center.branch
      @branch2 = @client2.center.branch

      # We'll give the loans some easy to distinguish amounts to make tests a little less brittle
      @loans = [
        Factory(:disbursed_loan, :client => @client1, :amount => 51),
        Factory(:disbursed_loan, :client => @client1, :amount => 62),
        Factory(:disbursed_loan, :client => @client2, :amount => 73),
        Factory(:disbursed_loan, :client => @client2, :amount => 84),
        Factory(:disbursed_loan, :client => @client2, :amount => 95)
      ]
    end

    # This one isn't working yet...
#    it "should report correct amount of disbursed loans" do
#      disbursal_date = Date.new( 2011, 12, 01 )
#
#      # We'll set the disbursal dates at 10 day increments
#      @loans.each_with_index do |loan, index|
#        loan.update :disbursal_date => disbursal_date + (index * 10)
#        # The loans_disbursed_between method uses histories to determine when a loan was disbursed
#        loan.history_disabled = false
#        loan.update_history
#      end
#
#      # At the start date only the first loan should be reported
#      Branch.loans_disbursed_between( disbursal_date, disbursal_date + 1, 'count' ).should        eql({ @branch1.id => 1 })
#      Branch.loans_disbursed_between( disbursal_date, disbursal_date + 1, 'sum' ).should          eql({ @branch1.id => 51 })
#
#      # Between 10 and 20 days we should see loans 2 and 3 belonging to center 1 and 2 respectively
#      Branch.loans_disbursed_between( disbursal_date + 10, disbursal_date + 20, 'count' ).should  eql({ @branch1.id => 1, @branch2.id => 1 })
#      Branch.loans_disbursed_between( disbursal_date + 10, disbursal_date + 20, 'sum' ).should    eql({ @branch1.id => 135 })
#
#      # Between day 20 and 30 we should see the third and fourth loans
#      Branch.loans_disbursed_between( disbursal_date + 20, disbursal_date + 30, 'count' ).should  eql({ @branch1.id => 1, @branch2.id => 2 })
#      Branch.loans_disbursed_between( disbursal_date + 20, disbursal_date + 30, 'sum' ).should    eql({ @branch1.id => 135 })
#    end

  end
end
