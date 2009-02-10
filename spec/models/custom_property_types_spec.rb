require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe HoursAndMinutes do

  describe ".new" do
    it "should create a Class" do
      HoursAndMinutes.new.should be_instance_of(Class)
    end
 
    it "should create unique a Class each call" do
      HoursAndMinutes.new.should_not == HoursAndMinutes.new
    end
  end
 
  describe ".dump" do
    it "should return the hours and minutes as a Fixnum (hhmm)" do
      HoursAndMinutes.dump('1010', :property).should == 1010
    end
 
    it "should be able flexible in accepting string representations of hh:mm" do
      HoursAndMinutes.dump('0', :property).should == 0
      HoursAndMinutes.dump('100', :property).should == 100
      HoursAndMinutes.dump('23:00', :property).should == 2300
      HoursAndMinutes.dump('23:0', :property).should == 2300
      HoursAndMinutes.dump("10'10", :property).should == 1010
      HoursAndMinutes.dump('12.59', :property).should == 1259
      HoursAndMinutes.dump('12,59', :property).should == 1259
      HoursAndMinutes.dump('2359', :property).should == 2359
      HoursAndMinutes.dump('3:0', :property).should == 300
      HoursAndMinutes.dump('1.0', :property).should == 100
      HoursAndMinutes.dump(10.0, :property).should == 1000
      HoursAndMinutes.dump(23.50, :property).should == 2350
      HoursAndMinutes.dump(21.00, :property).should == 1200
      HoursAndMinutes.dump(2.0, :property).should == 200
      HoursAndMinutes.dump(1200, :property).should == 1200
      HoursAndMinutes.dump(300, :property).should == 300
      HoursAndMinutes.dump(0, :property).should == 0
    end

    it "should raise an ArgumentError when trying to feed it rubbish/typos/etc as input" do
      HoursAndMinutes.dump(2400, :property).should raise_error(ArgumentError)
      HoursAndMinutes.dump('2::0', :property).should raise_error(ArgumentError)
      HoursAndMinutes.dump('-2', :property).should raise_error(ArgumentError) 
      HoursAndMinutes.dump('12122', :property).should raise_error(ArgumentError)
      HoursAndMinutes.dump(:hhmm, :property).should raise_error(ArgumentError)
      HoursAndMinutes.dump(1060, :property).should raise_error(ArgumentError)
      HoursAndMinutes.dump(1099, :property).should raise_error(ArgumentError)
      HoursAndMinutes.dump('1060', :property).should raise_error(ArgumentError)
      HoursAndMinutes.dump('10:60', :property).should raise_error(ArgumentError)
    end

    it "should return nil if given nil" do
      HoursAndMinutes.dump(nil, :property).should be_nil
    end
 
    it "should return an empty string if the value is an empty string" do
      HoursAndMinutes.dump("", :property).should == ""
    end
  end
 
  describe ".load" do
    it "should return the weekday as a symbol" do
      HoursAndMinutes.load(1212, :property).should == '12:12'
    end

    it "should raise an ArgumentError when feeding it rubbish" do
      HoursAndMinutes.load(-1, :property).should raise_error(ArgumentError)
      HoursAndMinutes.load(2400, :property).should raise_error(ArgumentError)
      HoursAndMinutes.load(60, :property).should raise_error(ArgumentError)
      HoursAndMinutes.load(99, :property).should raise_error(ArgumentError)
      HoursAndMinutes.load(160, :property).should raise_error(ArgumentError)
      HoursAndMinutes.load(199, :property).should raise_error(ArgumentError)
      HoursAndMinutes.load(3000, :property).should raise_error(ArgumentError)
      HoursAndMinutes.load((1..7), :property).should raise_error(ArgumentError)
      HoursAndMinutes.load(Date.new, :property).should raise_error(ArgumentError)
      HoursAndMinutes.load(Object.new, :property).should raise_error(ArgumentError)
    end
 
    it "should return nil if given nil" do
      HoursAndMinutes.load(nil, :property).should be_nil
    end
 
    it "should return an empty string if the value is an empty string" do
      HoursAndMinutes.load("", :property).should == ""
    end
  end
 
  describe '.typecast' do
    it 'should do nothing if a HoursAndMinutes is provided' do
      hhmm = HoursAndMinutes.new
      HoursAndMinutes.typecast(hhmm, :property).should == @w
    end
 
    it 'should defer to .load if a Fixnum (primitive type) is provided' do
      HoursAndMinutes.should_receive(:load).with(1, :property)
      HoursAndMinutes.typecast(1, :property)
    end
  end

end









describe Weekday do

  describe ".new" do
    it "should create a Class" do
      Weekday.new.should be_instance_of(Class)
    end
 
    it "should create unique a Class each call" do
      Weekday.new.should_not == Weekday.new
    end
  end
 
  describe ".dump" do
    it "should return the weekday as a Fixnum" do
      Weekday.dump('Monday', :property).should == 1
    end
 
    it "should be able flexible in accepting String or Symbol representations of weekdays" do
      Weekday.dump('Monday', :property).should == 1
      Weekday.dump('mondays', :property).should == 1
      Weekday.dump('MONDAY', :property).should == 1
      Weekday.dump('TUE', :property).should == 2
      Weekday.dump('wednesday', :property).should == 3
      Weekday.dump('thursdays', :property).should == 4
      Weekday.dump('thu', :property).should == 4
      Weekday.dump('thuRSdays', :property).should == 4
      Weekday.dump('friday', :property).should == 5
      Weekday.dump('saturday', :property).should == 6
      Weekday.dump('sunDAY', :property).should == 7
      Weekday.dump('SUNdays', :property).should == 7
      Weekday.dump('SUN', :property).should == 7

      Weekday.dump(:monday, :property).should == 1
      Weekday.dump(:tuesday, :property).should == 2
      Weekday.dump(:wednesday, :property).should == 3
      Weekday.dump(:thursday, :property).should == 4
      Weekday.dump(:friday, :property).should == 5
      Weekday.dump(:saturday, :property).should == 6
      Weekday.dump(:sunday, :property).should == 7
    end

    it "should raise an ArgumentError when trying to feed it rubbish/typos/etc as input" do
      Weekday.dump('mondayz', :property).should raise_error(ArgumentError)
      Weekday.dump('mo', :property).should raise_error(ArgumentError)
      Weekday.dump(:mon, :property).should raise_error(ArgumentError)      # promote symbol consistency
      Weekday.dump(:mondays, :property).should raise_error(ArgumentError)  # promote symbol consistency
      Weekday.dump('sathurday', :property).should raise_error(ArgumentError)
      Weekday.dump('tursday', :property).should raise_error(ArgumentError)
    end

    it "should return nil if given nil" do
      Weekday.dump(nil, :property).should be_nil
    end
 
    it "should return an empty string if the value is an empty string" do
      Weekday.dump("", :property).should == ""
    end
  end
 
  describe ".load" do
    it "should return the weekday as a symbol" do
      Weekday.load(1, :property).should == :monday
      Weekday.load(2, :property).should == :tuesday
      Weekday.load(3, :property).should == :wednesday
      Weekday.load(4, :property).should == :thursday
      Weekday.load(5, :property).should == :friday
      Weekday.load(6, :property).should == :saturday
      Weekday.load(7, :property).should == :sunday
      Weekday.load(7.0, :property).should == :sunday
      Weekday.load('7', :property).should == :sunday
    end

    it "should raise an ArgumentError when feeding it rubbish" do
      Weekday.load(0, :property).should raise_error(ArgumentError)
      Weekday.load(8, :property).should raise_error(ArgumentError)
      Weekday.load(-1, :property).should raise_error(ArgumentError)
      Weekday.load(100, :property).should raise_error(ArgumentError)
      Weekday.load(100, :property).should raise_error(ArgumentError)

      Weekday.load((1..7), :property).should raise_error(ArgumentError)
      Weekday.load(Date.new, :property).should raise_error(ArgumentError)
      Weekday.load(Object.new, :property).should raise_error(ArgumentError)
    end
 
    it "should return nil if given nil" do
      Weekday.load(nil, :property).should be_nil
    end
 
    it "should return an empty string if the value is an empty string" do
      Weekday.load("", :property).should == ""
    end
  end
 
  describe '.typecast' do
    it 'should do nothing if a Weekday is provided' do
      w = Weekday.new
      Weekday.typecast(w, :property).should == @w
    end
 
    it 'should defer to .load if a Fixnum (primitive type) is provided' do
      Weekday.should_receive(:load).with(1, :property)
      Weekday.typecast(1, :property)
    end
  end

end

