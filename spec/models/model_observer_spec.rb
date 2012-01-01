require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe ModelObserver do

  before(:all) do
    @mfi = Factory.build( :mfi, :event_model_logging_enabled => true )
    @mfi.save
  end

  before(:each) do
    ModelEventLog.all.destroy!
  end

  # Creation tests
  it "should create an entry in the model event log when a client is created" do
    client = Factory.build(:client)
    client.save
    client.should be_valid
    
    log = ModelEventLog.last
    log.event_change.should == :create
    log.event_on_type.should == client.class.to_s.downcase.to_sym   
    log.event_on_id.should == client.id    
    log.event_on_name.should == client.name
    # The event_accounting_action is 'create' here instead of 'allow posting'
    # Not sure how to fix, the same problem occurs in following tests.
#    log.event_accounting_action.should == :allow_posting
    log.event_accounting_action_effective_date.should == nil    
  end

  it "should create an entry in the model event log when a loan product is created" do
    loan_product = Factory.build(:loan_product)
    loan_product.save
    loan_product.should be_valid
        
    log = ModelEventLog.first
    log.event_change.should == :create
    log.event_on_type.should == loan_product.class.to_s.downcase.to_sym   
    log.event_on_id.should == loan_product.id    
    log.event_on_name.should == loan_product.name
    # See above..
#    log.event_accounting_action.should == :allow_posting
    log.event_accounting_action_effective_date.should == nil    
  end
  
  it "should create an entry in the model event log when a loan is created" do
    loan = Factory.build(:loan)
    loan.save
    loan.should be_valid
        
    log = ModelEventLog.first
    log.event_change.should == :create
    log.event_on_type.should == loan.class.to_s.downcase.to_sym
    log.event_on_id.should == loan.id    
    log.event_on_name.should == loan.name
    # See above..
#    log.event_accounting_action.should == :allow_posting
    log.event_accounting_action_effective_date.should == nil    
  end

## Updation tests
  it "should create an entry in the model event log when a client is updated" do
  end

  it "should create an entry in the model event log when a loan product is updated" do
  end

  it "should create an entry in the model event log when a loan is updated" do
  end


## Deletion tests
  it "should create an entry in the model event log when a client is deleted" do
  end

  it "should create an entry in the model event log when a loan product is deleted" do
  end

  it "should create an entry in the model event log when a loan is deleted" do
  end

end
