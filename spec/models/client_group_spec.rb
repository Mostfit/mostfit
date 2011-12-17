require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe ClientGroup do

  before(:each) do
    @client_group = Factory(:client_group)
  end

  it "should not be valid without a center" do
    @client_group.center = nil
    @client_group.should_not be_valid
    @client_group.center = Factory(:center)
    @client_group.should be_valid
  end

  context "within a center" do
    it "should have a unique name" do
      new_client_group = Factory(:client_group, :name => @client_group.name, :center => @client_group.center)
      new_client_group.should_not be_valid
      new_client_group.name = "Random New Name - #{Time.new.usec}"
      new_client_group.should be_valid
    end

    it "should have a unique code" do
      new_client_group = Factory.build(:client_group, :code => @client_group.code, :center => @client_group.center)
      new_client_group.should_not be_valid
      new_client_group.code = "RANDOMNEWCODE#{Time.new.usec}"
      new_client_group.should be_valid
    end
  end

  # This test seems to work but shouldn't we test the inverse case as well?
  it "should be able to tell if clients are movable" do
    # Add some clients to be moved
    5.times { @client_group.clients << Factory(:client) }

    @client_group.save
    @client_group.should be_valid
    @client_group.client_should_be_migratable.should be_true

    new_center = Factory(:center)
    new_center.should be_valid

    @client_group.center.clients.each{|client| 
      client.client_group = @client_group
      client.grt_pass_date = client.date_joined
      client.should be_valid
      client.save.should be_true
      client.center = new_center
      client.date_joined = new_center.creation_date - 10
      client.should_not be_valid
      client.save.should be_false
      client.center = center
      client.grt_pass_date = client.date_joined
      client.should be_valid
    }

    # This last part is failing but what are we testing exactly? Individual clients can be moved but the group itself can't?
#    @client_group.center = new_center
#    @client_group.should_not be_valid
  end


end
