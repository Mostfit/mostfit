require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/admin" do
  before(:each) do
    @response = request("/admin")
  end
end