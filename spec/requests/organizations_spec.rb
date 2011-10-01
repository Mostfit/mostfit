require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/organizations" do
  before(:each) do
    @response = request("/organizations")
  end
end