require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/center_meeting_days" do
  before(:each) do
    @response = request("/center_meeting_days")
  end
end