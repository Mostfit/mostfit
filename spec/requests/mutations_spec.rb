require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/mutations" do
  before(:each) do
    @response = request("/mutations")
  end
end