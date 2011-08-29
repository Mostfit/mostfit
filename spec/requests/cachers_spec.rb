require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/cachers" do
  before(:each) do
    @response = request("/cachers")
  end
end