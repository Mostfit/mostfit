require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe ClientGroup do
  before(:all) do
    load_fixtures :staff_members, :branches, :centers, :client_types, :clients
  end
    
  it "should have not be valid without a center" do
    cg = ClientGroup.new(:name => "group 1", :code => "g1", :number_of_members => 5)
    cg.should_not be_valid
    cg.center = Center.first
    cg.should be_valid
  end

  it "should have code uniqueness inside a center" do
    cg = ClientGroup.create(:name => "group 1", :code => "g1", :number_of_members => 5, :center => Center.first, 
                            :created_by_staff => Center.first.manager)
    cg.should be_valid

    # name same
    cg = ClientGroup.create(:name => "group 1", :code => "g2", :number_of_members => 5, :center => Center.first, 
                            :created_by_staff => Center.first.manager)
    cg.should_not be_valid

    cg = ClientGroup.create(:name => "group 2", :code => "g2", :number_of_members => 5, :center => Center.first, 
                            :created_by_staff => Center.first.manager)
    cg.should be_valid

    # code same
    cg = ClientGroup.create(:name => "group 3", :code => "g2", :number_of_members => 5, :center => Center.first, 
                            :created_by_staff => Center.first.manager)
    cg.should_not be_valid

    cg = ClientGroup.create(:name => "group 3", :code => "g3", :number_of_members => 5, :center => Center.get(2),
                            :created_by_staff => Center.first.manager)
    cg.should be_valid    
  end


  it "should be able to tell if clients are movable" do
    center = Center.first
    cg     = center.client_groups.first
    cg.client_should_be_migratable.should be_true
    center_2 = Center.get(2)
    
    center.clients.each{|client| 
      client.client_group = cg
      client.grt_pass_date = client.date_joined
      client.should be_valid
      client.save.should be_true
      client.center = center_2
      client.date_joined = center_2.creation_date - 10
      client.should_not be_valid
      client.save.should be_false
      client.center = center
      client.grt_pass_date = client.date_joined
      client.should be_valid
    }
    cg.center = center_2
    cg.should_not be_valid
  end


end
