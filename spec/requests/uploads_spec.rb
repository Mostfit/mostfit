require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/uploads" do
  before(:each) do
    @response = request("/uploads")
  end
end