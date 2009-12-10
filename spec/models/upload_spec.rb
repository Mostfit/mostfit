require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Upload do
  before(:all) do
    user=User.create(:role => :admin, :active => true, :login => 'admin', :password => 'password', :password_confirmation => 'password')
    Payment.all.destroy!
    Client.all.destroy!
    StaffMember.all.destroy! 
    Loan.all.destroy!
    FundingLine.all.destroy!
    Branch.all.destroy!
    Center.all.destroy!
    LoanProduct.all.destroy!
    file = Upload.new("upload_data.xls")
    #`cp #{File.join(Merb.root, "spec", "fixtures", file.filename)} /tmp/testing_upload.txt`
    FileUtils.cp(File.join(Merb.root, "spec", "fixtures", file.filename), File.join("/", "tmp", "testing_upload.xls"))
    file.move("/tmp/testing_upload.xls")
    file.process_excel_to_csv
    file.load_csv
  end
  
  it "Should create branches" do
    Branch.all.count.should > 0
  end

  it "Should create centers" do
    Center.all.count.should > 0
  end

  it "Should create clients" do
    Client.all.count.should > 0
  end

  it "Should create loans" do
    Loan.all.count.should > 0
  end

  it "Should create funding line" do
    FundingLine.all.count.should > 0
  end

  it "Should create payments" do
    Payment.all.count.should > 0
  end

  it "Should create loan products" do
    LoanProduct.all.count.should > 0
  end
end
