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
  desc "populate the database using the csv's"
  task :csv_to_database do
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

  desc "Check for anomalous entries "
  task :check_for_anomaly do
    date=Date.new(2009,4,1)#1st April,2009

    result_file=File.open("result_file.txt",'w')
    result_file.write("\t\t Name \t\t Expected \t\t Actual \n")

    staff_members = ['mithilesh','madhuri','manju','nirmala','rashida','usha']

    staff_members.each do |staff_member|#for each staff member
      result_file.write(" Staff Member :: #{staff_member.to_s}\n")
      center_id=nil
      staff_member_file=CSV.open("misfit_fixtures/#{staff_member}.csv",'r')#open his CSV file        
      staff_member_file.each do |row|#read each row
        if row[0]=='Centre name:-'
          center_id=row[1]
          result_file.write(" Center Name :: #{center_id.to_s}\n\n")
        elsif row[0]=~ /\d.\d+/
          client_refrence_id=center_id+row[0]
          loan=Loan.all('client.reference'=>client_refrence_id)[0]#get the loan corresponding to client's reference id
          if loan.principal_received_up_to(date)!=row[11].to_i #compare the expected and the actual value
            result_file.write("\t\t #{loan.client.name} \t\t #{loan.principal_received_up_to(date)} \t\t #{row[11]} \n")
          end
        end
    end
  end
end
