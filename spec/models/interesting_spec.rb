require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Interesting do
  
  it "1st April 2012 is in a leap year" do
    test_date = Date.parse("2012-4-1")
    Interesting.get_days_of_year(test_date).should == 366
  end

  it "1st March 2011 is not in a leap year" do
    test_date = Date.parse("2011-3-1")
    Interesting.get_days_of_year(test_date).should == 365
  end

  it "number of days in February 2012 is 29" do
    feb_2012 = Date.parse("2012-2-1")
    Interesting.number_of_days_in_month(feb_2012).should == 29
  end

  it "number of days in February 2011 is 28" do
    feb_2011 = Date.parse("2011-2-1")
    Interesting.number_of_days_in_month(feb_2011).should == 28
  end

  it "number of days in October 2011 is 31" do
    oct_2011 = Date.parse("2011-10-1")
    Interesting.number_of_days_in_month(oct_2011).should == 31
  end

  it "first of next month after December 2011 is 1st Jan 2012" do
    dec_2011 = Date.parse("2011-12-15")
    Interesting.first_of_next_month(dec_2011).should == Date.parse("2012-1-1")
  end

  it "first of next month after September 2011 is 1st October 2011" do
    sep_2011 = Date.parse("2011-9-11")
    Interesting.first_of_next_month(sep_2011).should == Date.parse("2011-10-1")
  end
  
end
