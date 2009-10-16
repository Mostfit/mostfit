require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/dashboard" do
  before(:each) do
    @response = request("/dashboard")
  end
end