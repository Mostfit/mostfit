require File.join( File.dirname(__FILE__), '..', "spec_helper" )

#
# This updated version of the User spec does not include the ACL tests of the original
# porting these would likely take considerable time and we're intending to implement a
# new ACL system soon, so this would likely be wasted efford.
# We will preserve the old user spec as user_spec.rb.old for reference
# 
#
describe User do

  before(:each) do
    User.all.destroy!

    @user = Factory(:user)
  end

  it "should not be valid with name shorter than 3 characters" do
    @user.login = "ok"
    @user.should_not be_valid
  end

  it "should not have a nil login " do
    @user.login=nil
    @user.should_not be_valid
  end

  it "should have a login name beginning with an alphanumeric character or underscore" do
    @user.login = "john"
    @user.should be_valid

    @user.login = "123john"
    @user.should be_valid

    @user.login = "_john"
    @user.should be_valid

    @user.login = "#kate"
    @user.should_not be_valid
  end

  it "should have a role" do
    @user.role = nil
    @user.should_not be_valid
  end

  it "should be return for admin? if admin value set to true" do
    @user.role = :admin
    @user.admin?.should be_true
  end

  # This was part of the original spec but there does not seem to be a validation against this
  # (and perhaps we don't really need one)
#  it "should be created before it is updated" do
#    @user.created_at = Date.new(2010, 01, 01)
#    @user.updated_at = Date.new(2009, 01, 01)
#    @user.should_not be_valid
#  end

end
