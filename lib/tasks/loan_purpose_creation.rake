require "merb-core"

Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace 'mostfit' do 
  desc "Load the data from Occupation in the LoanPurpose table."
  task :loan_purpose_creation do
    Occupation.all.each do |i|
      a = LoanPurpose.new(:id => i.id, :name => i.name, :code => i.code, :parent_id => 0)
      a.save
    end
  end
end

