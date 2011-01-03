require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Comment do

  it "should not be valid without a user" do
    comment = Comment.new(:parent_model => "Branch", :parent_id => Branch.first.id, :text => "hoh")
    comment.should_not be_valid    
  end
end
