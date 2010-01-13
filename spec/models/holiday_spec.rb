require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Holiday do
  
  before(:each) do
    Holiday.all.destroy!
    @h = Holiday.first_or_create(:name => "Makar Sankranti", :date => Date.parse('2009-03-03'), :shift_meeting => :before)
    @h.should be_valid
  end

  it "should have a name" do
    @h.name = nil
    @h.should_not be_valid
  end
  
  it "should have a date" do
    @h.date = nil
    @h.should_not be_valid
  end

  it "should have a behaivour" do
    @h.shift_meeting = nil
    @h.should_not be_valid
  end

  it "should update" do
    @h.shift_meeting = :after
    @h.save
    @h.errors.each {|e| puts "!!e"}
    @h.should be_valid
  end

  it "should have unique date" do
    @h1 = Holiday.new(:name => "Makar Sankranti 2", :date => Date.parse('2009-03-03'), :shift_meeting => :after)
    @h1.should_not be_valid
  end
end
