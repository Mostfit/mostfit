require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Posting do

  before (:all) do
    
    @user = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password',
                     :role => :admin)
    @user.save
    @user.should be_valid 

  it "should have specs"

end
