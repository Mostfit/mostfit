require 'test/unit'
require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Rules do

  before(:each) do
  end


  before(:all) do
  end

  it "should handle a basic condition" do
    @basic_condition1 = Mostfit::Business::BasicCondition.get_basic_condition(:var1 => "client.center.branch.centers.count", :binaryoperator => "", :var2 => 0, :comparator => :greater_than_equal,
                                                                             :const_value =>  5)
    @basic_condition1.var1.should "client.center.branch.centers.count"
    @basic_condition1.var2.should == 0
    @basic_condition1.comparator.should == :>=
    @basic_condition1.const_value.should == 5
  end

  it "should handle a basic condition" do
    @basic_condition1 = Mostfit::Business::BasicCondition.get_basic_condition(:var1 => "client.center.branch.centers.count", :binaryoperator => "", :var2 => 0, :comparator => :greater_than,
                                                                             :const_value =>  5)
    @basic_condition1.var1.should "client.center.branch.centers.count"
    @basic_condition1.var2.should == 0
    @basic_condition1.comparator.should == :>
    @basic_condition1.const_value.should == 5
  end

  it "should handle a basic condition" do
    @basic_condition1 = Mostfit::Business::BasicCondition.get_basic_condition(:var1 => "client.center.branch.centers.count", :binaryoperator => "", :var2 => 0, :comparator => :less_than,
                                                                             :const_value =>  5)
    @basic_condition1.var1.should "client.center.branch.centers.count"
    @basic_condition1.var2.should == 0
    @basic_condition1.comparator.should == :<
    @basic_condition1.const_value.should == 5
  end

  it "should handle a basic condition" do
    @basic_condition1 = Mostfit::Business::BasicCondition.get_basic_condition(:var1 => "client.center.branch.centers.count", :binaryoperator => "", :var2 => 0, :comparator => :less_than_equal,
                                                                             :const_value =>  5)
    @basic_condition1.var1.should "client.center.branch.centers.count"
    @basic_condition1.var2.should == 0
    @basic_condition1.comparator.should == :<=
    @basic_condition1.const_value.should == 5
  end

  it "should handle a basic condition" do
    @basic_condition1 = Mostfit::Business::BasicCondition.get_basic_condition(:var1 => "client.center.branch.centers.count", :binaryoperator => "", :var2 => 0, :comparator => :equal,
                                                                             :const_value =>  5)
    @basic_condition1.var1.should "client.center.branch.centers.count"
    @basic_condition1.var2.should == 0
    @basic_condition1.comparator.should == :==
    @basic_condition1.const_value.should == 5
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
    @complex_condition1.condition1.basic_condition.const_value.should == 5
    @complex_condition1.condition2.basic_condition.comparator.should == :<=
    @complex_condition1.condition2.basic_condition.var1.should "client.center.branch.centers.clients.count"
    @complex_condition1.condition2.basic_condition.var2.should == 0
    @complex_condition1.condition2.basic_condition.const_value.should == 50
  end

  it "should be able to add a new Rule" do
   Mostfit::Business::Rules.add({:name => :min_centers_and_clients_in_branch,
     :model_name => Loan, :on_action => :create,
     :condition => { :linking_operator => :and ,
       :first_condition => {:var1 => "client.center.branch.centers.count", :var2 => 0,
         :binaryoperator => "", :comparator => :greater_than_equal, :const_value => 5},
       :second_condition => { :var1 => "client.center.branch.centers.clients.count", :var2 => 0,
         :binaryoperator => "", :comparator => :greater_than_equal, :const_value => 5}
   } })
    Loan.new.respond_to?(:min_centers_and_clients_in_branch).should == true
  end

  it "should be able to handle rule on branch (model)" do
    Mostfit::Business::Rules.add :name => :number_of_branches_in_area,
      :model_name => Branch, :on_action => :create,
      :condition => {:var1 => "area.branches.count", :var2 => 0, :binaryoperator => "",
        :comparator => :less_than, :const_value => 2}

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
    @region.should be_valid
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

#  it "should be able to handle rule on Loan model" do
#   #TODO:not working, some problem discuss the loan thing with Piyush
#    h = { :name => :loans_more_than_10k, :model_name => Loan,
#          :on_action => :save,
#             :precondition => {:linking_operator => :and,
#               :first_condition => {:var1 => "disbursal_date", :var2 => 0,
#                 :comparator => :not, :const_value => nil},
#               :second_condition => {:var1 => "amount", :var2 => 0, 
#                 :comparator => :greater_than_equal, :const_value => 10000} },
#             :condition => {:var1 => :disbursed_by, :var2 => 0,
#               :comparator => :equal, :const_value => "client.center.branch.manager"}}
#    
#    Mostfit::Business::Rules.add h
#    Loan.new.respond_to?(:loans_more_than_10k).should == true
#
#
#    @region_manager = StaffMember.first_or_create(:name => "Region manager1")
#    @branch_manager = StaffMember.first_or_create(:name => "Branch manager1")
#    @area_manager = StaffMember.first_or_create(:name => "Area manager1")
#    @center_manager = StaffMember.first_or_create(:name => "Center manager1")
#    @region_manager.save
#    @branch_manager.save
#    @area_manager.save
#    @region_manager.should be_valid
#    @branch_manager.should be_valid
#    @area_manager.should be_valid
#    @region  = Region.first_or_create(:name => "test region3", :manager => @region_manager)
#    @region.should be_valid
#    @area = Area.first_or_create(:name => "test area3", :region => @region, :manager => @area_manager)
#    @area.save
#    @area.should be_valid
#
#    @branch = Branch.new(:name => "Kerela branch")
#    @branch.manager = @branch_manager
#    @branch.code = "br"
#    @branch.save
#    @branch.should be_valid
#
#    @center = Center.new(:name => "Munnar hill center")
#    @center.manager = @center_manager
#    @center.branch  = @branch
#    @center.code = "cen"
#    @center.save
#    @center.should be_valid
#
#    @funder = Funder.new(:name => "FWWB")
#    @funder.save
#    @funder.should be_valid
#
#    @funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2006-02-02", :first_payment_date => "2007-05-05", :last_payment_date => "2009-03-03")
#    @funding_line.funder = @funder
#    @funding_line.save
#    @funding_line.should be_valid
#
#    @client = Client.first_or_create(:name => 'Ms C.L. Ient', :reference => Time.now.to_s, :client_type => ClientType.create(:type => "Standard"))
#    @client.center  = @center
#    @client.date_joined = Date.parse('2006-01-01')
#    @client.created_by_user_id = 1
#    @client.save
#    @client.errors.each {|e| puts e}
#    @client.should be_valid
#
#    @loan_product = LoanProduct.new
#    @loan_product.name = "LP1"
#    @loan_product.max_amount = 1000
#    @loan_product.min_amount = 1000
#    @loan_product.max_interest_rate = 100
#    @loan_product.min_interest_rate = 0.1
#    @loan_product.installment_frequency = :weekly
#    @loan_product.max_number_of_installments = 25
#    @loan_product.min_number_of_installments = 25
#    @loan_product.loan_type = "DefaultLoan"
#    @loan_product.valid_from = Date.parse('2000-01-01')
#    @loan_product.valid_upto = Date.parse('2012-01-01')
#    @loan_product.save
#    @loan_product.errors.each {|e| puts e}
#    @loan_product.should be_valid
#
#    @loan = Loan.new(:amount => 1000, :interest_rate => 0.2, :installment_frequency => :weekly, :number_of_installments => 25, :scheduled_first_payment_date => "2000-12-06", :applied_on => "2000-02-01", :scheduled_disbursal_date => "2000-06-13")
#    @loan.history_disabled = true
#    @loan.applied_by       = @center_manager
#    @loan.funding_line     = @funding_line
#    @loan.client           = @client
#    @loan.loan_product     = @loan_product
#    @loan.valid?
#    @loan.approved_on = "2000-02-03"
#    @loan.approved_by = @manager
#    @loan.should be_valid
#
#    @client.destroy
#    @loan.destroy
#    @loan_product.destroy
#  end

end
