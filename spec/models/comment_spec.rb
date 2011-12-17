require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Comment do

  before(:each) do
    Comment.all.destroy!
    @comment = Factory(:comment)
  end

  it "should be valid with default attributes" do
    @comment.should be_valid
  end

  it "should not be valid without a user" do
    @comment.user = nil
    @comment.should_not be_valid    
  end
end
