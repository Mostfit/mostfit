require "rubygems"
require 'csv'

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')


namespace :aaj do
  desc "Create yaml for aajeevika CSVs"
  task :csv_to_yaml do
    DataMapper.auto_migrate! if Merb.orm == :datamapper
    staff_yaml_file = File.open("misfit_fixtures/aaj_staff_members.yml","w")
    loan_yaml_file = File.open("misfit_fixtures/aaj_loans.yml","w")
    branch_yaml_file = File.open("misfit_fixtures/aaj_branches.yml","w")
    center_yaml_file = File.open("misfit_fixtures/aaj_centers.yml","w")
    client_yaml_file = File.open("misfit_fixtures/aaj_clients.yml","w")
    staffs = ['mithilesh','madhuri','manju','nirmala','rashida','usha']
    funder = Funder.new(:name => 'icicici')
    funder.save
    funding_line = FundingLine.new(:funder => funder, :amount => 1000000, :interest_rate => 0.12, :disbursal_date => Date.parse("2008-01-01"))
    funding_line.save
    branch_manager = StaffMember.new(:name => 'Rashida Bano')
    branch_manager.save
    staff_yaml_file.write(branch_manager.to_yaml)
    @s = nil
    bawana = Branch.new(:name => 'Bawana', :manager => branch_manager)
    holambi = Branch.new(:name => 'Holambi', :manager => branch_manager)
    branches = {'mithilesh' => bawana, 'rashida' => bawana, 'nirmala' => bawana,
                'manju' => holambi, 'madhuri' => holambi, 'usha' => holambi}
    staffs.each do |staff|
      branch = Branch.new(:name => 'Holambi', :manager => branch_manager)
      branch_yaml_file.write(branch.to_yaml)
      csv = CSV::read("misfit_fixtures/#{staff}.csv")
      while l = csv.shift
        p l
        if l[0] == "Staff name:-"
          if StaffMember.all(:name=>l[1]).blank?
            @s = StaffMember.new
            @s.name = l[1].to_s
	    @s.save
            staff_yaml_file.write(@s.to_yaml)
          end
        elsif l[0] == "Centre name:-"
          c = Center.new
          c.manager = @s
          c.name = l[1].to_s
          c.meeting_day= l[9].downcase.to_s
#	  mt = l[4].split(":")
          c.meeting_time_hours= 9 #mt[0].to_i
          c.meeting_time_minutes= 30 #mt[1].to_i
	  c.branch = branches[staff]
          if c.save
	  else
	   p c.errors
           raise
	  end
          center_yaml_file.write(c.to_yaml)
        elsif l[0] =~ /\d.\d+/
          cl = Client.new
          cl.name = l[1].to_s
          cl.spouse_name = l[2].to_s
          cl.address = l[3].to_s
	  cl.center = c
	  cl.reference = c.name + l[0]
	  cl.save
          p [cl.errors, cl] if not cl.valid?
          client_yaml_file.write(cl.to_yaml)

          loan = Loan.new
          loan.amount = l[6].to_i
	  loan.interest_rate = 0.18
	  loan.installment_frequency = :weekly
	  loan.number_of_installments = 50
	  ad = l[4].gsub(".","/").split('/')
          p ad
	  d = Date.new(ad[2].to_i < 2000 ? ad[2].to_i + 2000 : ad[2].to_i ,ad[1].to_i,ad[0].to_i)
	  p d.to_s
	  loan.scheduled_disbursal_date = d
	  loan.approved_on = d
	  loan.applied_on = d
	  loan.applied_by = StaffMember.get(2)
	  loan.approved_by = loan.applied_by
	  loan.disbursal_date = loan.scheduled_disbursal_date
	  loan.disbursed_by = loan.applied_by
	  loan.discriminator = "A50Loan"
	  loan.history_disabled = true
          loan.funding_line = funding_line
	  ad = l[9].gsub(".","/").split('/')
	  d = Date.new(ad[2].to_i < 2000 ? ad[2].to_i + 2000 : ad[2].to_i,ad[1].to_i,ad[0].to_i)	  
	  p d.to_s
	  loan.scheduled_first_payment_date = d
	  loan.client = cl
	  if loan.save
	    p "Loan saved succesfully"
	  else
	    p loan.errors
	      	  raise
	  end
          loan_yaml_file.write(loan.to_yaml)
        end
      end

    end
  end


  desc "Create yaml from Aajeevika CSVs, mangle the names and create a mock database"
  task :csv_to_mock do
    DataMapper.auto_migrate! if Merb.orm == :datamapper
    staff_yaml_file = File.open("misfit_fixtures/mock_staff_members.yml","w")
    loan_yaml_file = File.open("misfit_fixtures/mock_loans.yml","w")
    branch_yaml_file = File.open("misfit_fixtures/mock_branches.yml","w")
    center_yaml_file = File.open("misfit_fixtures/mock_centers.yml","w")
    client_yaml_file = File.open("misfit_fixtures/mock_clients.yml","w")
    staffs = ['madhuri_old','usha']
    funder = Funder.new(:name => 'icicici')
    funder.save
    funding_line = FundingLine.new(:funder => funder, :amount => 1000000, :interest_rate => 0.12, :disbursal_date => Date.parse("2008-01-01"))
    funding_line.save
    branch_manager = StaffMember.new(:name => 'Fatima')
    branch_manager.save
    staff_yaml_file.write(branch_manager.to_yaml)
    branch1 = Branch.new(:name => 'Mumbai', :manager => branch_manager)
    branch1.save
    branch_yaml_file.write(branch1.to_yaml)
    branch_manager = StaffMember.new(:name => 'Feroza')
    branch_manager.save
    staff_yaml_file.write(branch_manager.to_yaml)
    branch2 = Branch.new(:name => 'Dilli', :manager => branch_manager)
    branch2.save
    branch_yaml_file.write(branch2.to_yaml)
    @s = nil
    staffs.each do |staff|
      csv = CSV::read("misfit_fixtures/#{staff}.csv")
      while l = csv.shift
        p l
        if l[0] == "Staff name:-"
          if StaffMember.all(:name=>l[1]).blank?
            @s = StaffMember.new
            @s.name = l[1].to_s
	    @s.save
            staff_yaml_file.write(@s.to_yaml)
          end
        elsif l[0] == "Centre name:-"
          c = Center.new
          c.manager = @s 
          c.name = l[1].to_s.gsub("AHP","JQZ")
          c.meeting_day= l[7].downcase.to_s
#	  mt = l[4].split(":")
          c.meeting_time_hours= 9 #mt[0].to_i
          c.meeting_time_minutes= 30 #mt[1].to_i
          c.branch = s.name.downcase == 'usha' ? branch1 : branch2
          if c.save
	  else
	   p c.errors
	  end
          center_yaml_file.write(c.to_yaml)
        elsif l[0] =~ /\d.\d+/
          cl = Client.new
          cl.name = "Client " + l[0]
          cl.spouse_name = "Spouse Name"
          cl.address = l[3].to_s
	  cl.center = c
	  cl.reference = c.name + l[0]
	  cl.save
          p [cl.errors, cl] if not cl.valid?
          client_yaml_file.write(cl.to_yaml)
          loan = Loan.new
          loan.amount = l[6].to_i
	  loan.interest_rate = 0.18
	  loan.installment_frequency = :weekly
	  loan.number_of_installments = 50
          ad = l[4].split('/')
          p ad
	  d = Date.new(ad[2].to_i < 2000 ? ad[2].to_i + 2000 : ad[2].to_i ,ad[1].to_i,ad[0].to_i)
	  p d.to_s
	  loan.scheduled_disbursal_date = d
	  loan.approved_on = d
	  loan.applied_on = d
	  loan.applied_by = StaffMember.get(2)
	  loan.approved_by = loan.applied_by
	  loan.disbursal_date = loan.scheduled_disbursal_date
	  loan.disbursed_by = loan.applied_by
	  loan.discriminator = "A50Loan"
	  loan.history_disabled = true
          loan.funding_line = funding_line
	  ad = l[7].split('/')
	  d = Date.new(ad[2].to_i < 2000 ? ad[2].to_i + 2000 : ad[2].to_i,ad[1].to_i,ad[0].to_i)	  
	  p d.to_s
	  loan.scheduled_first_payment_date = d
	  loan.client = cl
	  if loan.save
	#    p "Loan saved succesfully"
	  else
	    p loan.errors
	      	  raise

	  end
          loan_yaml_file.write(loan.to_yaml)
        end
      end

    end
  end

end
