require File.join( File.dirname(__FILE__), '..', 'spec_helper')

describe Identified do
  
  it "should have correctly formatted name and id when the object has both" do
    BothNameAndId.new.name_and_id.should == "#{TEST_NAME} (#{TEST_ID})"
  end

  it "should have correctly formatted id alone when the object has no name and only id" do
    OnlyId.new.name_and_id.should == "(#{TEST_ID})"
  end

end

TEST_NAME = "Hashimoto"
TEST_ID = 23

class BothNameAndId; include Identified; def name; TEST_NAME; end; def id; TEST_ID; end; end
class OnlyId; include Identified; def id; TEST_ID; end; end