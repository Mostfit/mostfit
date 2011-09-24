require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/transaction_logs" do
  before(:each) do
    @response = request("/transaction_logs")
  end
end