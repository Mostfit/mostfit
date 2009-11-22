require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/browse" do
  before(:each) do
    @response = request("/browse")
  end
end