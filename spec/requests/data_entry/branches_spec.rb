require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper.rb')

describe "/data_entry/branches" do
  before(:each) do
    @response = request("/data_entry/branches")
  end
end