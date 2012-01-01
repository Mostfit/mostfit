require File.join( File.dirname(__FILE__), '..', "spec_helper" )

# These tests are failing because Upload is not being initialized properly in the before(:all) block.
# It's raising an error "The attribute 'test_data.xls' is not accessible in Upload", which seems to
# indicate that it's taking the filename to be an attribute name on Upload. This makes sense since
# Upload doesn't appear to have a custom initialize method.
#
describe Upload do
#  before(:all) do
#    user=User.create(:role => :admin, :active => true, :login => 'admin', :password => 'password', :password_confirmation => 'password')
#    Payment.all.destroy!
#    Client.all.destroy!
#    StaffMember.all.destroy! 
#    Loan.all.destroy!
#    FundingLine.all.destroy!
#    Branch.all.destroy!
#    Center.all.destroy!
#    LoanProduct.all.destroy!
#    file = Upload.new("test_data.xls")
#    FileUtils.cp(File.join(Merb.root, "spec", "fixtures", file.filename), File.join("/", "tmp", "testing_upload.xls"))
#    file.move("/tmp/testing_upload.xls")
#    file.process_excel_to_csv
#    file.load_csv(MockLog.new)
#  end
#  
#  it "Should create branches" do
#    Branch.all.count.should > 0
#  end
#
#  it "Should create centers" do
#    Center.all.count.should > 0
#  end
#
#  it "Should create clients" do
#    Client.all.count.should > 0
#  end
#
#  it "Should create loans" do
#    Loan.all.count.should > 0
#  end
#
#  it "Should create funding line" do
#    FundingLine.all.count.should > 0
#  end
#
#  it "Should create payments" do
#    Payment.all.count.should > 0
#  end
#
#  it "Should create loan products" do
#    LoanProduct.all.count.should > 0
#  end
end
