require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/graph_data" do
  before(:each) do
    @response = request("/graph_data")
  end
end