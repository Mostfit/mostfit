require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a asset_register exists" do
  AssetRegister.all.destroy!
end

given "an admin user exist" do
  load_fixtures :users
  response = request url(:perform_login), :method => "PUT", :params => {:login => "admin", :password => "password"}
  response.should redirect
end

describe "resource(:asset_registers)", :given => "an admin user exist" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:asset_registers))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of asset_registers" do
      pending
      @response.should have_xpath("//ul")
    end
  end
  
  describe "GET", :given => "a asset_register exists" do
    before(:each) do
      @response = request(resource(:asset_registers))
    end
    
    it "has a list of asset_registers" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST", :given => "an admin user exist" do
    before(:each) do
      AssetRegister.all.destroy!
      @response = request(resource(:asset_registers, :new), :method => "POST", :params => { :asset_register => { :name => "Ramu", :issue_date => '17-02-2011',
                              :returned_date => '27-02-2011', :branch_id => 3, :manager_staff_id => 10, :asset_type => "Lappy"}})
    end
    
    it "redirects to resource(:asset_registers)" do
      pending
      @response.should redirect_to(resource(:asset_registers), :message => {:notice => "Asset entry was successfully entered"})
    end
  end
end

describe "resource(@asset_register)", :given => "an admin user exist" do 
  describe "a successful DELETE", :given => "a asset_register exists" do
    before(:each) do
      pending
      @response = request(resource(AssetRegister.first), :method => "DELETE")
    end

    it "should redirect to the index action" do
      @response.should redirect_to(resource(:asset_registers))
    end
  end
end

describe "resource(:asset_registers, :new)", :given => "an admin user exist" do
  before(:each) do
    @response = request(resource(:asset_registers, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@asset_register, :edit)", :given => "a asset_register exists" do
  before(:each) do
    pending
    @response = request(resource(AssetRegister.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@asset_register)", :given => "a asset_register exists" do
  
  describe "GET" do
    before(:each) do
      pending
      @response = request(resource(AssetRegister.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @asset_register = AssetRegister.first
      pending
      @response = request(resource(@asset_register), :method => "PUT", :params => { :asset_register => {:id => @asset_register.id} })
    end
  
    it "redirect to the asset_register show action" do
      @response.should redirect_to(resource(@asset_register))
    end
  end
end
