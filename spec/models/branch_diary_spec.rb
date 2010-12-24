require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe BranchDiary do
  
  before(:all) do
    StaffMember.all.destroy!
    @manager = StaffMember.new(:name => "Mr. Prakash Jha")
    @manager.save
    @manager.errors
    @manager.should be_valid
  end

  before(:all) do
    Branch.all.destroy!
    @branch = Branch.new(:name => "Lucknow")
    @branch.manager = @manager
    @branch.code = "branch"
    @branch.save
    @branch.errors.each {|e| p e}
    @branch.should be_valid
  end
  
  before(:each) do
    BranchDiary.all.destroy!
    @branch_diary = BranchDiary.new
    @branch_diary.manager = @manager
    @branch_diary.branch = @branch
    @branch_diary.diary_date = '20-12-2010'
    @branch_diary.opening_time_hours = 10
    @branch_diary.opening_time_minutes = 30
    @branch_diary.closing_time_hours = 20
    @branch_diary.closing_time_minutes = 30
    @branch_diary.branch_key = "Mr. Ramesh Taurani"
    @branch_diary.save
    @branch_diary.errors.each {|e| p e}
    @branch_diary.should be_valid
  end
  
  it "should not be valid without a manager who opens the branch" do
    @branch_diary.manager = nil
    @branch_diary.should_not be_valid
  end

  it "should belong to a particular branch" do
    @branch_diary.branch = @branch
    @branch_diary.should be_valid
  end

  it "should not be valid without a branch" do
    @branch_diary.branch = nil
    @branch_diary.should_not be_valid
  end

  it "should not be valid without today's date" do
    @branch_diary.diary_date = nil
    @branch_diary.should_not be_valid
  end

  it "should have a unique date with respect to a branch" do
    @branch_diary.branch = @branch
    @branch_diary.diary_date = '20-12-2010'
    @branch_diary.should be_valid
  end

  it "should not be valid without the opening time of branch" do
    @branch_diary.opening_time_hours = nil
    @branch_diary.opening_time_minutes = nil
    @branch_diary.should_not be_valid
  end

  it "should be valid without the closing time of branch" do
    @branch_diary.closing_time_hours = nil
    @branch_diary.closing_time_minutes = nil
    @branch_diary.should be_valid
  end

  it "should not be valid without a person holding the branch key" do
    @branch_diary.branch_key = nil
    @branch_diary.should_not be_valid
  end

end
