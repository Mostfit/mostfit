require "rubygems"
require "fastercsv"
require "merb-core"
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'huge')
names = FasterCSV.parse(File.read("db/names.csv")).flatten
len = names.length

user = User.first
client_type = ClientType.create(:type => "Standard client")

days  = [:monday, :tuesday, :wednesday, :thursday, :friday]
numbers = {}
numbers[:region] = 2
numbers[:area]   = 2
numbers[:branch] = 10
numbers[:center] = 50

unless @loan_product = LoanProduct.first(:name => "LP1")
  @loan_product = LoanProduct.new
  @loan_product.name = "LP1"
  @loan_product.max_amount = 10000
  @loan_product.min_amount = 10000
  @loan_product.max_interest_rate = 15
  @loan_product.min_interest_rate = 15
  @loan_product.installment_frequency = :weekly
  @loan_product.max_number_of_installments = 50
  @loan_product.min_number_of_installments = 50
  @loan_product.loan_type = "DefaultLoan"
  @loan_product.valid_from = Date.parse('2000-01-01')
  @loan_product.valid_upto = Date.parse('2020-01-01')
  @loan_product.save
  @loan_product.errors.each {|e| puts e}
end

@funder = Funder.new(:name => "FWWB")
@funder.save

@funding_line = FundingLine.new(:amount => 10_000_000, :interest_rate => 0.15, :purpose => "for women", :disbursal_date => "2000-02-02", 
                                :first_payment_date => "2000-05-05", :last_payment_date => "2010-12-31")
@funding_line.funder = @funder
@funding_line.save


region_manager =  StaffMember.create(:name => "Region manager", :active => true, :creation_date => Date.today)
p region_manager.errors unless region_manager.valid?

1.upto(numbers[:region]){|region_id| 
  region = Region.create(:manager => region_manager, :name => "Region#{region_id}", :creation_date => Date.today)  
  if region.valid?
    puts "Region #{region.name} created" 
  else
    p region.errors
  end
  1.upto(numbers[:area]){|area_id|
    area_manager = StaffMember.create(:name => "Area#{area_id} manager", :active => true, :creation_date => Date.today)
    area = Area.create(:name => "Area#{region_id*area_id}", :manager => area_manager, :region => region)
    puts "  Area #{area.name} created"
    1.upto(numbers[:branch]){|branch_id|
      branch_manager = StaffMember.first(:name => "Branch#{branch_id} manager") || StaffMember.create(:name => "Branch#{branch_id} manager", 
                                                                                                      :active => true, :creation_date => Date.today)
      branch = Branch.new
      branch.name = "Branch#{region_id*area_id*branch_id}"
      branch.code = "R#{region_id}A#{area_id}B#{branch_id}"
      branch.area = area
      branch.manager = branch_manager
      branch.save
      puts "    Branch #{branch.name} created"
      center_manager = nil
      1.upto(numbers[:center]){|center_id|
        if center_id%20==1
          center_manager = StaffMember.create(:name => "R#{region_id}A#{area_id}B#{branch_id} Cen#{center_id} manager", :active => true, :creation_date => Date.today)
        end
        next if Center.first(:code => "#{branch.code}C#{center_id}")
        center = Center.new
        center.branch = branch
        center.manager = center_manager
        center.name = "Center#{center_id}"
        center.code = branch.code + "C#{center_id}"
        center.meeting_day = days[center_id%5 - 1]
        center.meeting_time_hours   = "#{7+center_id%5}"
        center.meeting_time_minutes = 0
        unless center.save
          p center.errors
        end
        1.upto(5){|group_id|
          ClientGroup.create(:name => "Group #{group_id}", :code => group_id, :center => center)
        }
      }
      puts "      Centers & groups for branch #{branch.name} created"
    }
  }
}

counter=0
Branch.all.each{|branch|
  puts "Branch #{branch.name}: data entry"
  branch.centers.each{|center|
    center.client_groups.each{|grp|
      5.times{|x|
        unless client = Client.first(:reference => "#{branch.code}#{center.code}#{grp.code}#{x}")
          client = Client.new(:name => names[counter % len], :reference => "#{branch.code}#{center.code}#{grp.code}#{x}", :center => center, :created_by => user, 
                              :created_by_staff => center.manager, :date_joined => Date.today-((rand()*100).to_i), :client_type => client_type, :client_group => grp,
                              :client_type => client_type)
          unless client.save
            p client.errors
          end
        end
        next if client.loans.count>0
        date = Date.new(2000+(10*rand()).to_i, (12*rand()).to_i+1, (28*rand()).to_i+1)
        loan = DefaultLoan.new(:amount => 10000, :amount_applied_for => 10000, :amount_sanctioned => 10000, :interest_rate => 0.15, :discriminator => DefaultLoan,
                               :installment_frequency => :weekly, :funding_line => @funding_line, :loan_product => @loan_product,
                               :number_of_installments => 50, :scheduled_disbursal_date => date + 7, :scheduled_first_payment_date => date + 14,
                               :applied_on => date, :approved_on => date + 3, :disbursal_date => date + 7, :applied_by => center.manager, :created_by => user,
                               :approved_by => center.branch.manager, :disbursed_by => center.manager, :client => client, :loan_product => @loan_product)
        unless loan.save
          p loan.errors
        end
        counter+=1
      }
    }
    puts "    Client and loans for center #{center.name} created"
  }
  puts "  Client and loans for branch #{branch.name} created"
}
