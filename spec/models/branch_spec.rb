require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Branch do

  before(:all) do
    Center.all.destroy!
    StaffMember.all.destroy!
    @manager = Factory( :staff_member )
    @manager.should be_valid
  end

  before(:each) do
    Branch.all.destroy!
    @branch = Factory(:branch)
  end

  it "should be valid with default attributes" do
    @branch.should be_valid
  end
 
  it "should not be valid without a manager" do
    @branch.manager = nil
    @branch.should_not be_valid
  end
 
  it "should not be valid without a name" do
    @branch.name = nil
    @branch.should_not be_valid
  end

  it "should not be valid with a name shorter than 3 characters" do
    @branch.name = "ok"
    @branch.should_not be_valid
  end
 
 it "should valid with a name more than 3 character" do
  @branch.name = "branch"
  @branch.should be_valid
  end
 
  it "should not be valid without a creation_date " do
    @branch.creation_date= nil
    @branch.should_not be_valid
  end
 
  it "should not be valid without a code" do
   @branch.code= nil
   @branch.should_not be_valid
  end

  it "should not be valid with a code greater than 10 character" do
   @branch.code="1234567890123"
   @branch.should_not be_valid
  end

  it "should be valid with code" do
   @branch.code="ok"
   @branch.should be_valid
  end    

  it"should be valid without contact number" do
   @branch.contact_number= nil
   @branch.should be_valid
   end

 it "should not be valid with contact_number grater than 40 character" do
   @branch.contact_number="12345678901234567890123456789012345678901234567890"
   @branch.should_not be_valid
  end

 it "should be valid with contact_number less than 40 character" do
   @branch.contact_number="1235678901234567890"
   @branch.should be_valid
  end

  it"should be valid without landmark name" do
  @branch.landmark= nil
  @branch.should be_valid
 end
  it"should be valid with a landmark name  less than 100 character" do
  @branch.landmark="abcdefghijklmnopqrstuvwxyz"
  @branch.should be_valid
 end

  it"should  not be valid with a landmark name more  than 100 character" do
  @branch.landmark="abcdefghijklmnopqrstuvwxyzasdsdsdfsfghgfhgfghfhfghdfsdfgfdgfsfdgfdfsgfdgfdgfcgfdfghdfdgfdghdgfsgcghdgshgdgdfhdghfdghfhdgfdgdgfcgdddhfdghdghhjgjgjfghfhjghfghfgdjgdgfdfdfgfffhggfgfdgfdhgkhfkhjghgljghjftydtrsrfyufgxdfgfcgxdfzgfcgfzdszgfcgfzdfxjghcgfjhgyuflghjfjgdfxgc"
  @branch.should_not be_valid
 end
  
 it"should not be valid without area_id" do
  @branch.area_id=nil
  @branch.should_not be_valid
 end
 
 it"should be valid with area_id" do
  @branch.area_id="1"
  @branch.should be_valid
  end
 
  it "should be able to 'have' centers" do
    center = Factory(:center, :branch => @branch, :manager => @branch.manager)
    center.should be_valid

    @branch.should be_valid
    @branch.centers.count.should eql(1)
    @branch.centers.first.name.should eql(center.name)

    second_center = Factory(:center, :branch => @branch, :manager => @branch.manager)
    second_center.should be_valid

    @branch.should be_valid
    @branch.centers.count.should eql(2)
    @branch.centers.last.name.should eql(second_center.name)
  end

end
