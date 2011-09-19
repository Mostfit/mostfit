require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/model_event_logs" do
  before(:each) do
    @response = request("/model_event_logs")
  end
end