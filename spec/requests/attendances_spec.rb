require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/attendances" do
  before(:each) do
    @response = request("/attendances")
  end
end