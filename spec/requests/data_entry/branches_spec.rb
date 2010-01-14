require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper.rb')

given "a branch exists" do
  Branch.all.destroy!
end

describe "/data_entry/branches" do
  describe "GET" do
    
    before(:each) do
      u = User.new(:login => 'abcde', :password => 'abcde', :password_confirmation => 'abcde')
      p u.save
      request("/login", :method => 'PUT', :params => {:login => 'abcde', :password => 'abcde'})
      @response = request(resource(:enter_branch))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end
  end
end

