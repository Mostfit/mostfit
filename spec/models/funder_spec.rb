require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Funder do

  before(:each) do
    @funder = Factory(:funder)
    @funder.should be_valid
  end

  it "should not be valid without having a name" do
    @funder.name=nil
    @funder.should_not be_valid
  end

  it "should be able to have funding lines" do
    funding_line1 = Factory(:funding_line, :funder => @funder)
    funding_line1.should be_valid

    @funder.funding_lines.count.should eql(1)

    funding_line2 = Factory(:funding_line, :funder => @funder)
    funding_line2.should be_valid

    @funder.funding_lines.count.should eql(2)
  end

  # Note that completed_lines gives all funding lines with a last_payment_date BEFORE a given
  # date. If no date is given (as is the case here) "Date.today" is used.
  it "should give correct count of completed lines " do
    lambda {
      funding_line = Factory(:funding_line, :funder => @funder, :disbursal_date => Date.new(1999,01,01), :first_payment_date => Date.new(2000,01,01), :last_payment_date => Date.new(2001,01,01))
      funding_line.should be_valid
    }.should change( @funder, :completed_lines ).by(1)
  end

  # Note that active_lines gives all funding_lines with a disbursal_date and last_payment_date BEFORE
  # or EQUAL TO a given date. If no date is given (as is the case here) "Date.today" is used.
  it "should give correct count of active lines" do
    lambda {
      funding_line1 = Factory(:funding_line, :funder => @funder, :disbursal_date => Date.new(1999,01,01), :first_payment_date => Date.new(2000,01,01), :last_payment_date => Date.new(2001,01,01))
      funding_line1.should be_valid
      funding_line2 = Factory(:funding_line, :funder => @funder, :disbursal_date => Date.new(1999,01,01), :first_payment_date => Date.new(2000,01,01), :last_payment_date => Date.new(2001,01,01))
      funding_line2.should be_valid
    }.should change( @funder, :active_lines ).by(2)
  end

  # Note that total_lines gives all funding_lines with a disbursal_date AFTER a given date
  # If no date is given (as is the case here) "Date.today" is used.
  it "should give correct count of total lines " do
    lambda {
      funding_line1 = Factory(:funding_line, :funder => @funder, :disbursal_date => Date.today + 365, :first_payment_date => Date.today + 366, :last_payment_date => Date.today + 367)
      funding_line1.should be_valid
      funding_line2 = Factory(:funding_line, :funder => @funder, :disbursal_date => Date.today + 365, :first_payment_date => Date.today + 366, :last_payment_date => Date.today + 367)
      funding_line2.should be_valid
    }.should change( @funder, :total_lines ).by(2)
  end

end
