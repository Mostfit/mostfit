require 'test/unit'
require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Rules do

  before(:each) do
  end

  before(:all) do
    @center_manager = StaffMember.first_or_create(:name => "Center manager1")
    @center_manager.save
    @center_manager.should be_valid
    @branch_manager = StaffMember.first_or_create(:name => "Branch manager1")
    @branch_manager.save
    @branch_manager.should be_valid
    @branch = Branch.new(:name => "Kerela branch1")
    @branch.manager = @branch_manager
    @branch.code = "br1"
    @branch.save
    @branch.should be_valid
    @center = Center.new(:name => "Munnar hill center1")
    @center.manager = @center_manager
    @center.branch  = @branch
    @center.code = "cen1"
    @center.save
    @center.should be_valid
    
    @cg = ClientGroup.first_or_create(:name => "DummyGroup1", :code => "97", :center_id => 1, :created_by_staff_member_id => @branch_manager.id)
    @cg.save
    @cg.should be_valid
    
    @c1 = Client.first_or_create(:name => 'Dummy Client1', :reference => Time.now.to_s+"1",
                                 :client_type => ClientType.create(:type => "Standard"),
                                 :center  => @center, :date_joined => Date.parse('2010-01-01') )
    @c1.created_by_user_id = @branch_manager.id
    @c1.client_group = @cg
    @c1.save
    @c1.should be_valid
    
    @funder = Funder.new(:name => "FWWB")
    @funder.save
    @funder.should be_valid

    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
    @funding_line.funder = @funder
    @funding_line.save
    @funding_line.should be_valid

    @loan_product = LoanProduct.new
    @loan_product.name = "LP1"
    @loan_product.max_amount = 100000
    @loan_product.min_amount = 1000
    @loan_product.max_interest_rate = 100
    @loan_product.min_interest_rate = 0.1
    @loan_product.installment_frequency = :weekly
    @loan_product.max_number_of_installments = 25
    @loan_product.min_number_of_installments = 25
    @loan_product.loan_type = "DefaultLoan"
    @loan_product.valid_from = Date.parse('2000-01-01')
    @loan_product.valid_upto = Date.parse('2012-01-01')
    @loan_product.save
    @loan_product.errors.each {|e| puts e}
    @loan_product.should be_valid
  end


  it "should handle a basic condition" do
    @basic_condition1 = Mostfit::Business::BasicCondition.get_basic_condition(:var1 => "client.center.branch.centers.count", :binaryoperator => "", :var2 => 0, :comparator => :greater_than_equal, :const_value =>  5)
    @basic_condition1.var1.should "client.center.branch.centers.count"
    @basic_condition1.var2.should == 0
    @basic_condition1.comparator.should == :>=
      @basic_condition1.const_value.should == 4
  end

  it "should handle a basic condition" do
    @basic_condition1 = Mostfit::Business::BasicCondition.get_basic_condition(:var1 => "client.center.branch.centers.count", :binaryoperator => "", :var2 => 0, :comparator => :greater_than, :const_value =>  5)
    @basic_condition1.var1.should "client.center.branch.centers.count"
    @basic_condition1.var2.should == 0
    @basic_condition1.comparator.should == :>
    @basic_condition1.const_value.should == 4
  end

  it "should handle a basic condition" do
    @basic_condition1 = Mostfit::Business::BasicCondition.get_basic_condition(:var1 => "client.center.branch.centers.count", :binaryoperator => "", :var2 => 0, :comparator => :less_than,
                                                                              :const_value =>  5)
    @basic_condition1.var1.should "client.center.branch.centers.count"
    @basic_condition1.var2.should == 0
    @basic_condition1.comparator.should == :<
    @basic_condition1.const_value.should == 4
  end

  it "should handle a basic condition" do
    @basic_condition1 = Mostfit::Business::BasicCondition.get_basic_condition(:var1 => "client.center.branch.centers.count", :binaryoperator => "", :var2 => 0, :comparator => :less_than_equal,
                                                                              :const_value =>  5)
    @basic_condition1.var1.should "client.center.branch.centers.count"
    @basic_condition1.var2.should == 0
    @basic_condition1.comparator.should == :<=
      @basic_condition1.const_value.should == 4
  end

  it "should handle a basic condition" do
    @basic_condition1 = Mostfit::Business::BasicCondition.get_basic_condition(:var1 => "client.center.branch.centers.count", :binaryoperator => "", :var2 => 0, :comparator => :equal,
                                                                              :const_value =>  5)
    @basic_condition1.var1.should "client.center.branch.centers.count"
    @basic_condition1.var2.should == 0
    @basic_condition1.comparator.should == :==
    @basic_condition1.const_value.should == 4
  end

  # A complex condition consists of one or two complex conditions attached by a linking operator
  # let C1, C2, C3 and C4 be complex conditions
  # C1 = { :linking_operator => "not", :first_condition => C2 }
  # C2 = { :linking_operator => "and", #and or or
  #       :first_condition => C3 ,
  #       :second_condition => C4}
  # C3 = {:var1 => "id", #interpreted as model_name.var1
  #       :binaryoperator => "minus", #relation between var1 and var2, only plus or minus allowed here
  #       :var2 => "some_other_property", #interpreted as model_name.var2
  #       :comparator => :less_than , #less_than, less_than_equal, equal, not etc.
  #       :const_value => 5, #final const value
  #       COMPLETE EVALUATION IS OF
  #       var1 BINARYOPERATOR var2 COMPARATOR const_value
  #       so there are two types of conditions, one contains linking_operator, first_condition and second_condition(like C1, C2)
  #       other contains var1, var2, binaryoperator, comparator, const_value (like C3)
  #       if var1 is neither int nor date, than var2 is ignoreed and binaryoperator should be empty string


  it "should handle a complex condition" do
    @complex_condition1 = Mostfit::Business::ComplexCondition.get_condition(
                                                                            :linking_operator => :and,
                                                                            :first_condition => {:var1 => "client.center.branch.centers.count", :var2=>0,
                                                                              :binaryoperator => "", :comparator => :greater_than_equal, :const_value => 5 } ,
                                                                            :second_condition => {:var1 => "client.center.branch.centers.clients.count", :var2 => 0,
                                                                              :binaryoperator => "", :comparator => :less_than_equal, :const_value => 50})
    @complex_condition1.is_basic_condition.should == false
    @complex_condition1.operator.should == :and
      @complex_condition1.condition1.should_not be_nil
    @complex_condition1.condition2.should_not be_nil
    @complex_condition1.condition1.is_basic_condition.should == true
    @complex_condition1.condition2.is_basic_condition.should == true
    @complex_condition1.condition1.basic_condition.comparator.should == :>=
      @complex_condition1.condition1.basic_condition.var1.should "client.center.branch.centers.count"
    @complex_condition1.condition1.basic_condition.var2.should == 0
    @complex_condition1.condition1.basic_condition.const_value.should == 4
    @complex_condition1.condition2.basic_condition.comparator.should == :<=
      @complex_condition1.condition2.basic_condition.var1.should "client.center.branch.centers.clients.count"
    @complex_condition1.condition2.basic_condition.var2.should == 0
    @complex_condition1.condition2.basic_condition.const_value.should == 49
  end

  it "should be able to add a new Rule" do
    h = {:name => :min_centers_and_clients_in_branch,
      :model_name => Loan, :on_action => :create,
      :condition => { :linking_operator => :and ,
        :first_condition => {:var1 => "client.center.branch.centers.count", :var2 => 0,
          :binaryoperator => "", :comparator => :greater_than_equal, :const_value => 5},
        :second_condition => { :var1 => "client.center.branch.centers.clients.count", :var2 => 0,
          :binaryoperator => "", :comparator => :greater_than_equal, :const_value => 5}
      } }
    Mostfit::Business::Rules.add h
    Loan.new.respond_to?(:min_centers_and_clients_in_branch).should == true
    Mostfit::Business::Rules.remove h
  end

  it "should be able to handle rule on branch (model)" do
    h = {:name => :number_of_branches_in_area,
      :model_name => Branch, :on_action => :create,
      :condition => {:var1 => "area.branches.count", :var2 => 0, :binaryoperator => "",
        :comparator => :less_than, :const_value => 2} }
    Mostfit::Business::Rules.add h

    @manager = StaffMember.first_or_create(:name => "Region manager1")
    @manager.save
    @manager.should be_valid
    @region  = Region.first_or_create(:name => "test region3", :manager => @manager)
    @region.should be_valid
    @area = Area.first_or_create(:name => "test area2", :region => @region, :manager => @manager)
    @area.should be_valid
    @area.save

    Branch.all.destroy!
    Branch.new.respond_to?(:number_of_branches_in_area).should == true

    @branch1 = Branch.new(:name => "My branch1")
    @branch2 = Branch.new(:name => "My branch2")
    @branch1.area = @area
    @branch2.area = @area
    @branch1.manager = @manager
    @branch2.manager = @manager
    @branch1.code = "B1"
    @branch2.code = "B2"
    @branch1.save
    @branch1.should be_valid
    @branch2.save
    @branch2.should_not be_valid
    @area.should be_valid
    @branch1.destroy
    @branch2.destroy

    Mostfit::Business::Rules.remove h
  end

  it "should be able to remove a rule" do
    h = {:name => :number_of_branches_in_area,
      :model_name => Branch, :on_action => :create,
      :condition => {:var1 => "area.branches.count", :var2 => 0, :binaryoperator => "",
        :comparator => :less_than, :const_value => 2} }
    Mostfit::Business::Rules.add h

    @manager = StaffMember.first_or_create(:name => "Region manager1")
    @manager.save
    @manager.should be_valid
    @region  = Region.first_or_create(:name => "test region3", :manager => @manager)
    @region.should be_valid
    @area = Area.first_or_create(:name => "test area2", :region => @region, :manager => @manager)
    @area.should be_valid
    @area.save

    Branch.all.destroy!
    Branch.new.respond_to?(:number_of_branches_in_area).should == true

    @branch1 = Branch.new(:name => "My branch1")
    @branch2 = Branch.new(:name => "My branch2")
    @branch1.area = @area
    @branch2.area = @area
    @branch1.manager = @manager
    @branch2.manager = @manager
    @branch1.code = "B1"
    @branch2.code = "B2"
    @branch1.save
    @branch1.should be_valid
    @branch2.save
    @branch2.should_not be_valid
    @area.should be_valid

    Mostfit::Business::Rules.remove h

    @branch2.should be_valid #since the rule has been removed
    @branch1.destroy
    @branch2.destroy

  end

  it "should be able to handle rules on center model" do
    h = {:name => :max_centers_in_area, :model_name => Center, :on_action => :create,
      :condition => { :linking_operator => :not,
        :first_condition => { :var1 => "branch.area.branches.centers.count",
          :var2 => 0, :binaryoperator => "", :comparator => :greater_than_equal,
          :const_value => 3} } }
    Mostfit::Business::Rules.add h 
    Center.new.respond_to?(:max_centers_in_area)
    Branch.all.destroy!
    Area.all.destroy!
    Region.all.destroy!
    @region_manager = StaffMember.first_or_create(:name => "Region manager1")
    @region  = Region.first_or_create(:name => "test region3", :manager => @region_manager)
    @region.should be_valid
    @region.save
    @area_manager = StaffMember.first_or_create(:name => "Area manager1")
    @center_manager = StaffMember.first_or_create(:name => "Center manager1")
    @center_manager.save
    @center_manager.should be_valid
    @branch_manager = StaffMember.first_or_create(:name => "Branch manager1")
    @branch_manager.save
    @branch_manager.should be_valid
    @area = Area.first_or_create(:name => "test area4", :region => @region, :manager => @area_manager)
    @branch = Branch.first_or_create(:name => "Kerela branch")
    @branch.manager = @branch_manager
    @branch.code = "brad"
    @branch.area = @area
    @area.save
    @branch.save
    @branch.should be_valid
    @center1 = Center.new(:name => "center 1")
    @center1.manager = @center_manager
    @center1.branch  = @branch
    @center1.code = "cen"
    @center1.save
    @center1.errors.each {|e| puts e}
    @center1.should be_valid

    @center2 = Center.new(:name => "center 2")
    @center2.manager = @center_manager
    @center2.branch  = @branch
    @center2.code = "cer"
    @center2.save
    @center2.errors.each {|e| puts e}
    @center2.should be_valid

    @center3 = Center.new(:name => "center 3")
    @center3.manager = @center_manager
    @center3.branch  = @branch
    @center3.code = "ces"
    @center3.save
    @center3.errors.each {|e| puts e}
    @center3.should_not be_valid
    Mostfit::Business::Rules.remove h 

  end

  it "should handle rule on Area model" do
    h = {:name => :area_should_be_part_of_region,
      :model_name => Area, :on_action => :create,
      :condition => {:var1 => "region", :var2 => 0, :comparator => :not, :const_value => nil}}
    Mostfit::Business::Rules.add h
    Center.new.respond_to?(:max_centers_in_area)
    Branch.all.destroy!
    Area.all.destroy!
    Region.all.destroy!
    @region_manager = StaffMember.first_or_create(:name => "Region manager1")
    @region  = Region.first_or_create(:name => "test region3", :manager => @region_manager)
    @region.should be_valid
    @region.save
    @area_manager = StaffMember.first_or_create(:name => "Area manager1")
    @area1 = Area.first_or_create(:name => "test area4", :region => @region, :manager => @area_manager)
    @area1.errors.each {|e| puts e}
    @area1.should be_valid
    @area2 = Area.first_or_create(:name => "test area5", :manager => @area_manager)
    @area2.should_not be_valid #since region is null
    Mostfit::Business::Rules.remove h

  end

  it "should handle rule on Region model" do
    h = {:name => :max_areas_in_region, :model_name => Region, :on_action => :save,
      :condition => { :var1 => "areas.count", :var2 => 0, :binaryoperator => "",
        :comparator => :less_than, :const_value => 3} }
    Mostfit::Business::Rules.add h
    @region_manager = StaffMember.first_or_create(:name => "Region manager1")
    @region  = Region.first_or_create(:name => "test region3", :manager => @region_manager)
    @region.should be_valid
    @region.save
    @area_manager = StaffMember.first_or_create(:name => "Area manager1")
    @area1 = Area.first_or_create(:name => "test area4", :region => @region, :manager => @area_manager)
    @area1.should be_valid
    @region.should be_valid
    @area2 = Area.first_or_create(:name => "test area6", :region => @region, :manager => @area_manager)
    @area2.should be_valid
    @region.should_not be_valid
    @area3 = Area.first_or_create(:name => "test area7", :region => @region, :manager => @area_manager)
    @area3.should be_valid
    @region.should_not be_valid
    @region.save
    Mostfit::Business::Rules.remove h
  end

  it "should handle string comparison rule" do
    forbidden_region_name = "lalbagh"
    h = {:name => :name_of_region, :model_name => Region, :on_action => :save,
      :condition => { :var1 => "name", :var2 => 0, :binaryoperator => "",
        :comparator => :not, :const_value => forbidden_region_name} }
    Mostfit::Business::Rules.add h
    @region_manager = StaffMember.first_or_create(:name => "Region manager1")
    @region  = Region.first_or_create(:name => forbidden_region_name, :manager => @region_manager)
    @region.should_not be_valid
    @region.name = "something"
    @region.should be_valid
    @region.save
    Mostfit::Business::Rules.remove h

  end

  it "should handle date comparison rule" do
    forbidden_date = Date.parse("2009-01-01")
    h = {:name => :creation_date_of_region, :model_name => Region, :on_action => :save,
      :condition => { :var1 => "creation_date", :var2 => 0, :binaryoperator => "",
        :comparator => :not, :const_value => forbidden_date} }
    Mostfit::Business::Rules.add h
    @region_manager = StaffMember.first_or_create(:name => "Region manager1")
    @region  = Region.first_or_create(:manager => @region_manager)
    @region.creation_date = forbidden_date
    @region.should_not be_valid
    @region.creation_date = forbidden_date+1
    @region.should be_valid
    @region.save
    Mostfit::Business::Rules.remove h

  end

  it "should handle two variable date comparison rule" do
    date1 = Date.today
    h = {:name => :creation_date_of_region, :model_name => Region, :on_action => :save,
      :condition => { :var1 => "creation_date", :var2 => "manager.creation_date",
        :binaryoperator => "minus", :comparator => :greater_than, :const_value => 1} }
    Mostfit::Business::Rules.add h
    @region_manager = StaffMember.first_or_create(:name => "Region manager1")
    @region_manager.creation_date = date1 #this is of no effect actually since the region_manager creation date is automatically assigned to be date.today
    @region  = Region.first_or_create(:manager => @region_manager)
    @region.creation_date = date1 - 1
    @region.should_not be_valid
    @region.creation_date = date1+2
    @region.should be_valid
    @region.save
    Mostfit::Business::Rules.remove h

  end


  it "TESTCASE01:should not permit more than 5 clients in a client group" do
    h = {:name => :max_clients_in_a_group, :model_name => Client, :on_action => :save,
      :condition => { :var1 => "client_group.clients.count", :var2 => 0,
        :binaryoperator => "", :comparator => :less_than_equal , :const_value => 5} }
    Mostfit::Business::Rules.add h
    
    cg = ClientGroup.first_or_create(:name => "DummyGroup1", :code => "97", :center_id => 5, :created_by_staff_member_id => @branch_manager.id)
    cg.save
    cg.should be_valid

    @center_manager = StaffMember.first_or_create(:name => "Center manager1")
    @center_manager.save
    @center_manager.should be_valid
    @branch_manager = StaffMember.first_or_create(:name => "Branch manager1")
    @branch_manager.save
    @branch_manager.should be_valid
    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @branch_manager
    @branch.code = "br"
    @branch.save
    @branch.should be_valid
    @center = Center.new(:name => "Munnar hill center")
    @center.manager = @center_manager
    @center.branch  = @branch
    @center.code = "cen"
    @center.save
    @center.should be_valid

    c1 = Client.first_or_create(:name => 'Dummy Client11', :reference => Time.now.to_s+"11",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => @center, :date_joined => Date.parse('2010-01-01') )
    c1.created_by_user_id = @branch_manager.id
    c1.client_group = cg
    c1.save
    c1.should be_valid

    c2 = Client.first_or_create(:name => 'Dummy Client12', :reference => Time.now.to_s+"12",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => @center, :date_joined => Date.parse('2010-01-01') )
    c2.created_by_user_id = @branch_manager.id
    c2.client_group = cg
    c2.save
    c2.should be_valid

    c3 = Client.first_or_create(:name => 'Dummy Client3', :reference => Time.now.to_s+"3",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => @center, :date_joined => Date.parse('2010-01-01') )
    c3.created_by_user_id = @branch_manager.id
    c3.client_group = cg
    c3.save
    c3.should be_valid

    c4 = Client.first_or_create(:name => 'Dummy Client4', :reference => Time.now.to_s+"4",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => @center, :date_joined => Date.parse('2010-01-01') )
    c4.created_by_user_id = @branch_manager.id
    c4.client_group = cg
    c4.save
    c4.should be_valid

    c5 = Client.first_or_create(:name => 'Dummy Client5', :reference => Time.now.to_s+"5",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => @center, :date_joined => Date.parse('2010-01-01') )
    c5.created_by_user_id = @branch_manager.id
    c5.client_group = cg
    c5.save
    c5.should_not be_valid

    c6 = Client.first_or_create(:name => 'Dummy Client6', :reference => Time.now.to_s+"6",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => @center, :date_joined => Date.parse('2010-01-01') )
    c6.created_by_user_id = @branch_manager.id
    c6.client_group = cg
    c6.save
    c6.should_not be_valid

    c1.destroy!
    c2.destroy!
    c3.destroy!
    c4.destroy!
    c5.destroy!
    c6.destroy!
    cg.destroy!

    Mostfit::Business::Rules.remove h
  end

  it "(TESTCASE02) should not allow less than 3 clients in group" do     
    h = {:name => :min_clients_limit_in_group, :model_name => Loan, :on_action => :save,
      :condition => { :var1 => "client.client_group.clients.count", :var2 => 0,
        :binaryoperator => "", :comparator => :greater_than_equal, :const_value => 3} }
    Mostfit::Business::Rules.add h
    
    cg = ClientGroup.first_or_create(:name => "DummyGroup12", :code => "107", :center_id => 1, :created_by_staff_member_id => @branch_manager.id)
    cg.save
    cg.should be_valid
    
    c2 = Client.first_or_create(:name => 'Dummy Client', :reference => Time.now.to_s+"2",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => @center, :date_joined => Date.parse('2010-01-01') )
    c2.created_by_user_id = @branch_manager.id
    c2.client_group = cg
    c2.save
    c2.should be_valid
    
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13")
    @loan.history_disabled = true
    @loan.applied_by       = @branch_manager
    @loan.funding_line     = @funding_line
    @loan.client           = c2
    @loan.loan_product     = @loan_product
    @loan.valid?
    @loan.errors.each {|e| puts e}
    @loan.should_not be_valid
    @loan.destroy!
    
    c2.destroy!
    cg.destroy!
    Mostfit::Business::Rules.remove h
  end


  it "(TESTCASE03) should not disburse loan if no of clients in group less than 3" do     
    h = {:name => :min_clients_limit_in_group, :model_name => Loan, :on_action => :save,
      :condition => { :var1 => "client.client_group.clients.count", :var2 => 0,
        :binaryoperator => "", :comparator => :greater_than_equal, :const_value => 3} }
    Mostfit::Business::Rules.add h

    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13")
    @loan.history_disabled = true
    @loan.applied_by       = @branch_manager
    @loan.funding_line     = @funding_line
    @loan.client           = @c1
    @loan.loan_product     = @loan_product
    @loan.valid?
    @loan.errors.each {|e| puts e}
    @loan.should_not be_valid
    @loan.destroy!
    Mostfit::Business::Rules.remove h
  end

  it "(TESTCASE04) should not allow centers of branch1 to have more than 2 clients while centers of other branches can have as many clients as they want" do
    branch1_name = "Dummy Branch1"
    h = {:name => :max_clients_limit_for_a_particular_branch, :model_name => Client, :on_action => :save,
      :precondition => { :var1 => "center.branch.name", :comparator => :equal, :var2 => 0,
        :const_value => branch1_name },
      :condition => { :var1 => "center.branch.centers.clients.count", :var2 => 0,
        :binaryoperator => "", :comparator => :less_than_equal, :const_value => 2} }
    Mostfit::Business::Rules.add h 

    region_manager = StaffMember.first_or_create(:name => "Dummy Region manager1")
    region  = Region.first_or_create(:name => "Dummy region1", :manager => region_manager)
    region.should be_valid
    region.save
    area_manager = StaffMember.first_or_create(:name => "Dummy area manager1")
    center_manager = StaffMember.first_or_create(:name => "Dummy Center Manager1")
    center_manager.save
    center_manager.should be_valid
    branch_manager = StaffMember.first_or_create(:name => "Dummy Branch manager1")
    branch_manager.save
    branch_manager.should be_valid
    area = Area.first_or_create(:name => "dummy area1", :region => region, :manager => area_manager)
    area.save

    branch1 = Branch.first_or_create(:name => branch1_name)
    branch1.manager = branch_manager
    branch1.code = "dummycode1"
    branch1.area = area
    branch1.save
    branch1.should be_valid

    branch2 = Branch.first_or_create(:name => "Dummy Branch2")
    branch2.manager = branch_manager
    branch2.code = "dummycode2"
    branch2.area = area
    branch2.save
    branch2.should be_valid

    center1 = Center.new(:name => "dummy center1")
    center1.manager = center_manager
    center1.branch  = branch1
    center1.code = "cen"
    center1.save
    center1.errors.each {|e| puts e}
    center1.should be_valid

    center2 = Center.new(:name => "dummy center2")
    center2.manager = center_manager
    center2.branch  = branch2
    center2.code = "cen2"
    center2.save
    center2.errors.each {|e| puts e}
    center2.should be_valid

    c1 = Client.first_or_create(:name => 'Dummy Client1', :reference => Time.now.to_s+"1",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => center1, :date_joined => Date.parse('2010-01-01') )
    c1.created_by_user_id = branch_manager.id
    c1.save
    c1.should be_valid

    c2 = Client.first_or_create(:name => 'Dummy Client2', :reference => Time.now.to_s+"2",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => center1, :date_joined => Date.parse('2010-01-01') )
    c2.created_by_user_id = branch_manager.id
    c2.save
    c2.should_not be_valid

    c3 = Client.first_or_create(:name => 'Dummy Client3', :reference => Time.now.to_s+"3",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => center1, :date_joined => Date.parse('2010-01-01') )
    c3.created_by_user_id = branch_manager.id
    c3.save
    c3.should_not be_valid

    c4 = Client.first_or_create(:name => 'Dummy Client4', :reference => Time.now.to_s+"4",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => center2, :date_joined => Date.parse('2010-01-01') )
    c4.created_by_user_id = branch_manager.id
    c4.save
    c4.should be_valid

    c5 = Client.first_or_create(:name => 'Dummy Client5', :reference => Time.now.to_s+"5",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => center2, :date_joined => Date.parse('2010-01-01') )
    c5.created_by_user_id = branch_manager.id
    c5.save
    c5.should be_valid
    
    c6 = Client.first_or_create(:name => 'Dummy Client6', :reference => Time.now.to_s+"6",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => center2, :date_joined => Date.parse('2010-01-01') )
    c6.created_by_user_id = branch_manager.id
    c6.save
    c6.should be_valid

    c1.destroy!
    c2.destroy!
    c3.destroy!
    c4.destroy!
    c5.destroy!
    c6.destroy!

    center1.destroy!
    center2.destroy!
    branch1.destroy! 
    branch2.destroy! 
    area.destroy!
    region.destroy!
    branch_manager.destroy!
    area_manager.destroy!
    region_manager.destroy!

    Mostfit::Business::Rules.remove h
  end

  it "(TESTCASE05) branch manager should not be able to disburse more than 10K loan" do     
    
    h = {:name => :should_not_disburse_more_than_10k_loan, :model_name => Loan, :on_action => :save, 
      :precondition => { :var1 => "disbursed_by_staff_id", :var2 => 0,
        :binaryoperator => "", :comparator => :equal,:const_value => @branch_manager.id},
      :condition => { :var1 => "amount_sanctioned", :var2 => 0 ,:binaryoperator => "", :comparator => :less_than_equal ,:const_value =>10000 }}

    Mostfit::Business::Rules.add h
    
    @loan = Loan.new(:amount => 10001, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-02-10")
    @loan.history_disabled = true
    @loan.applied_by       = @branch_manager
    @loan.approved_by      = @branch_manager
    @loan.disbursed_by     = @branch_manager
    @loan.funding_line     = @funding_line
    @loan.client           = @c1
    @loan.loan_product     = @loan_product
    @loan.valid?
    @loan.approved_on     = "2000-02-04"
    @loan.disbursal_date  = "2000-02-10"
    @loan.amount_sanctioned = @loan.amount
    @loan.save
    @loan.errors.each {|e| puts e}
    @loan.should_not be_valid
    @loan.destroy!

    Mostfit::Business::Rules.remove h
  end

  it "(TESTCASE06) loan should not be disbursed if it is older than 5 days" do     
    h = {:name => :should_not_disburse_5days_old_loan, :model_name => Loan, :on_action => :save,
      :condition => { :var1 => "scheduled_disbursal_date", :var2 => 0,
        :binaryoperator => "", :comparator => :minus, :var3 => "applied_on",:binaryoperator => "", :comparator => :less_than_equal,:const_value => 5 } }
    Mostfit::Business::Rules.add h
    
    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => Date.parse("2000-02-01"), :scheduled_disbursal_date => Date.parse("2000-02-10"))
    @loan.history_disabled = true
    @loan.applied_by       = @branch_manager
    @loan.funding_line     = @funding_line
    @loan.client           = @c1
    @loan.loan_product     = @loan_product
    @loan.disbursal_date   = Date.parse("2000-02-10")
    @loan.disbursed_by_staff_id = @branch_manager.id
    @loan.approved_on     = Date.parse("2000-02-09")
    @loan.approved_by     = @branch_manager
    @loan.valid?
    @loan.errors.each {|e| puts e}
    @loan.should_not be_valid
    
    @loan.destroy!
    Mostfit::Business::Rules.remove h

  end



  it "(TESTCASE07) Area manager should not disburse more than 50K loan" do     
    
    @area_manager = StaffMember.first_or_create(:name => "Area manager")
    @area_manager.save
    @area_manager.should be_valid
    @manager = StaffMember.first_or_create(:name => "Region manager1")
    @manager.save
    @manager.should be_valid
    @region  = Region.first_or_create(:name => "test region3", :manager => @manager)
    @region.should be_valid
    @area = Area.new(:name => "Maharastra")
    @area.manager = @area_manager
    @area.region  = @region
    @area.save
    @area.should be_valid

    h = {:name => :should_not_disburse_more_than_50k_loan, :model_name => Loan, :on_action => :save,
      #       :precondition => { :var1 => "disbursed_by_staff_id", :var2 => 0, #why this (pre)condition, it looks meaningless to me - ashishb
      #         :binaryoperator => "", :comparator => :equal,:const_value => 1},
      :condition => {:var1 => "amount_sanctioned",:var2 => 0 ,:binaryoperator => "", :comparator => :less_than_equal,:const_value =>50000 } }

    Mostfit::Business::Rules.add h
    
    @loan = Loan.new(:amount => 50001, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-02-10")
    @loan.history_disabled = true
    @loan.applied_by       = @area_manager
    @loan.approved_by      = @area_manager
    @loan.disbursed_by     = @area_manager
    @loan.funding_line     = @funding_line
    @loan.client           = @c1
    @loan.loan_product     = @loan_product
    @loan.valid?
    @loan.approved_on     = "2000-02-04"
    @loan.disbursal_date  = "2000-02-10"
    @loan.amount_sanctioned = @loan.amount
    @loan.save
    @loan.errors.each {|e| puts e}
    @loan.should_not be_valid
    
    @loan.destroy!
    p Mostfit::Business::Rules.remove h

  end

  it "(TESTCASE08)should not allow a new client in a branch when total clients in all centers of a branch are more equals 5" do
    h = {:name => :max_clients_per_branch, :model_name => Client, :on_action => :save,
      :condition => { :var1 => "center.branch.centers.clients.count", :var2 => 0,
        :binaryoperator => "", :comparator => :less_than_equal, :const_value => 5} }
    Mostfit::Business::Rules.add h 

    region_manager = StaffMember.first_or_create(:name => "Dummy Region manager1")
    region  = Region.first_or_create(:name => "Dummy region1", :manager => region_manager)
    region.should be_valid
    region.save
    area_manager = StaffMember.first_or_create(:name => "Dummy area manager1")
    center_manager = StaffMember.first_or_create(:name => "Dummy Center Manager1")
    center_manager.save
    center_manager.should be_valid
    branch_manager = StaffMember.first_or_create(:name => "Dummy Branch manager1")
    branch_manager.save
    branch_manager.should be_valid
    area = Area.first_or_create(:name => "dummy area1", :region => region, :manager => area_manager)
    branch = Branch.first_or_create(:name => "Dummy Branch1")
    branch.manager = branch_manager
    branch.code = "dummycode1"
    branch.area = area
    area.save
    branch.save
    branch.should be_valid

    center1 = Center.new(:name => "dummy center1")
    center1.manager = center_manager
    center1.branch  = branch
    center1.code = "cen"
    center1.save
    center1.errors.each {|e| puts e}
    center1.should be_valid

    center2 = Center.new(:name => "dummy center 2")
    center2.manager = center_manager
    center2.branch  = branch
    center2.code = "cen2"
    center2.save
    center2.errors.each {|e| puts e}
    center2.should be_valid


    c1 = Client.first_or_create(:name => 'Dummy Client1', :reference => Time.now.to_s+"1",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => center1, :date_joined => Date.parse('2010-01-01') )
    c1.created_by_user_id = branch_manager.id
    c1.save
    c1.should be_valid

    c2 = Client.first_or_create(:name => 'Dummy Client2', :reference => Time.now.to_s+"2",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => center1, :date_joined => Date.parse('2010-01-01') )
    c2.created_by_user_id = branch_manager.id
    c2.save
    c2.should be_valid

    c3 = Client.first_or_create(:name => 'Dummy Client3', :reference => Time.now.to_s+"3",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => center1, :date_joined => Date.parse('2010-01-01') )
    c3.created_by_user_id = branch_manager.id
    c3.save
    c3.should be_valid

    c4 = Client.first_or_create(:name => 'Dummy Client4', :reference => Time.now.to_s+"4",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => center1, :date_joined => Date.parse('2010-01-01') )
    c4.created_by_user_id = branch_manager.id
    c4.save
    c4.should be_valid

    c5 = Client.first_or_create(:name => 'Dummy Client5', :reference => Time.now.to_s+"5",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => center2, :date_joined => Date.parse('2010-01-01') )
    c5.created_by_user_id = branch_manager.id
    c5.save
    c5.should_not be_valid

    c6 = Client.first_or_create(:name => 'Dummy Client6', :reference => Time.now.to_s+"6",
                                :client_type => ClientType.create(:type => "Standard"),
                                :center  => center2, :date_joined => Date.parse('2010-01-01') )
    c6.created_by_user_id = branch_manager.id
    c6.save
    c6.should_not be_valid

    c1.destroy!
    c2.destroy!
    c3.destroy!
    c4.destroy!
    c5.destroy!
    c6.destroy!

    center1.destroy!
    center2.destroy!
    branch.destroy! 
    area.destroy!
    region.destroy!
    branch_manager.destroy!
    area_manager.destroy!
    region_manager.destroy!

    Mostfit::Business::Rules.remove h
  end

  it "(TESTCASE09) should not allow more than 5 areas in a region" do
    h = {:name => :max_areas_in_region, :model_name => Area, :on_action => :save,
      :condition => { :var1 => "region.areas.count", :var2 => 0, :binaryoperator => "",
        :comparator => :less_than, :const_value => 6} }
    Mostfit::Business::Rules.add h

    @region_manager = StaffMember.first_or_create(:name => "Region manager1")
    r1  = Region.first_or_create(:name => "Dummy region3", :manager => @region_manager)
    r1.should be_valid
    r1.save
    @area_manager = StaffMember.first_or_create(:name => "Area manager1")
    @area_manager.save
    a1 = Area.first_or_create(:name => "Dummy Area1", :region => r1, :manager => @area_manager)
    a1.should be_valid
    a2 = Area.first_or_create(:name => "Dummy Area2", :region => r1, :manager => @area_manager)
    a2.should be_valid
    a3 = Area.first_or_create(:name => "Dummy Area3", :region => r1, :manager => @area_manager)
    a3.should be_valid
    a4 = Area.first_or_create(:name => "Dummy Area4", :region => r1, :manager => @area_manager)
    a4.should be_valid
    a5 = Area.first_or_create(:name => "Dummy Area5", :region => r1, :manager => @area_manager)
    a5.should_not be_valid
    a6 = Area.first_or_create(:name => "Dummy Area6", :region => r1, :manager => @area_manager)
    a6.should_not be_valid

    a1.destroy!
    a2.destroy!
    a3.destroy!
    a4.destroy!
    a5.destroy!
    a6.destroy!
    r1.destroy!
    Mostfit::Business::Rules.remove h

  end

  it "(TESTCASE10) should not allow more than 4 centers per Staff Member" do
    h = {:name => :max_centers_per_staff_member, :model_name => Center, :on_action => :save,
      :condition => { :var1 => "manager.centers.count", :var2 => 0, :binaryoperator => "",
        :comparator => :less_than_equal, :const_value => 4} }
    Mostfit::Business::Rules.add h

    region_manager = StaffMember.first_or_create(:name => "Dummy Region manager1")
    region  = Region.first_or_create(:name => "Dummy region1", :manager => region_manager)
    region.should be_valid
    region.save
    area_manager = StaffMember.first_or_create(:name => "Dummy area manager1")
    center_manager = StaffMember.first_or_create(:name => "Dummy Center Manager1")
    center_manager.save
    center_manager.should be_valid
    branch_manager = StaffMember.first_or_create(:name => "Dummy Branch manager1")
    branch_manager.save
    branch_manager.should be_valid
    area = Area.first_or_create(:name => "dummy area1", :region => region, :manager => area_manager)
    branch = Branch.first_or_create(:name => "Dummy Branch1")
    branch.manager = branch_manager
    branch.code = "dummycode1"
    branch.area = area
    area.save
    branch.save
    branch.should be_valid
    center1 = Center.new(:name => "dummy center1")
    center1.manager = center_manager
    center1.branch  = branch
    center1.code = "cen"
    center1.save
    center1.errors.each {|e| puts e}
    center1.should be_valid

    center2 = Center.new(:name => "dummy center 2")
    center2.manager = center_manager
    center2.branch  = branch
    center2.code = "cen2"
    center2.save
    center2.errors.each {|e| puts e}
    center2.should be_valid

    center3 = Center.new(:name => "dummy center 3")
    center3.manager = center_manager
    center3.branch  = branch
    center3.code = "cen3"
    center3.save
    center3.errors.each {|e| puts e}
    center3.should be_valid

    center4 = Center.new(:name => "dummy center 4")
    center4.manager = center_manager
    center4.branch  = branch
    center4.code = "cen4"
    center4.save
    center4.errors.each {|e| puts e}
    center4.should_not be_valid

    center5 = Center.new(:name => "dummy center 5")
    center5.manager = center_manager
    center5.branch  = branch
    center5.code = "cen5"
    center5.save
    center5.errors.each {|e| puts e}
    center5.should_not be_valid

    center1.destroy!
    center2.destroy!
    center3.destroy!
    center4.destroy!
    center5.destroy!
    branch.destroy!
    area.destroy!
    region.destroy!
    branch_manager.destroy!
    area_manager.destroy!
    region_manager.destroy!

    Mostfit::Business::Rules.remove h

  end
  
  it "(TESTCASE11)Loan product of 50k & interest rate 10%-15%, 1k-10k interest 15%, 11k-25k interest 12.5% & 26k-50k interest 10%" do
    
    h = {:name => :should_disburse_loan_with_different_limit_and_interest_rate, :model_name => Loan, :on_action => :update,
      :precondition => { :linking_operator => :and ,
        :first_condition => { :var1 => "amount", :var2 => 0, :binaryoperator => "", :comparator => :less_than_equal, :const_value => 50000 },
        :second_condition => { :var1 => "amount", :var2 => 0, :binaryoperator => "", :comparator => :greater_than_equal, :const_value => 26000 } },
      :condition => { :var1 => "interest_rate", :var2 => 0, :binaryoperator => "", :comparator => :equal,:const_value => 0.10} }
    
    Mostfit::Business::Rules.add h
    
    @loan = Loan.new(:amount => 30000, :interest_rate => 0.15, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-02-10")
    @loan.history_disabled = true
    @loan.applied_by       = @branch_manager
    @loan.approved_by      = @branch_manager
    @loan.disbursed_by     = @branch_manager
    @loan.funding_line     = @funding_line
    @loan.client           = @c1
    @loan.loan_product     = @loan_product 
    @loan.approved_on     = "2000-02-04"
    @loan.disbursal_date  = "2000-02-10"
    @loan.amount_sanctioned = 10000
    @loan.save
    @loan.errors.each {|e| puts e}
    @loan.should_not be_valid
    @loan.interest_rate = 0.10
    @loan.should be_valid
    Mostfit::Business::Rules.remove h
  end
end  
