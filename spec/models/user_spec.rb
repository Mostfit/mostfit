require File.join( File.dirname(__FILE__), '..', "spec_helper" )


describe User do

  before(:each) do
    @user = User.new(:id=>10, :login=>"sparsh",:created_at=>"2002-11-23", :updated_at=>"2003-11-23", :role => :admin)
  end
  it "should not be valid with name shorter than 3 characters" do
    @user.login = "ok"
    @user.should_not be_valid
  end

  it "should not have a nil login " do
    @user.login=nil
    @user.should_not be_valid
  end

  it "should be return for admin? if admin value set to true" do
    @user.admin?.should==true
  end

  it "should be created before it is updated" do
    @user.created_at="23-11-2006"
    @user.updated_at="23-3-2005"
    @user.should_not be_valid
  end

  it "should have a login name beginning with numbers, aplphabets and underscores " do
    @user.login="#kate"
    @user.should_not be_valid	
  end

  it "should have a role" do
    @user.role = nil
    @user.should_not be_valid
  end

end
