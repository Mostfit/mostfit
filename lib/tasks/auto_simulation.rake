# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"
require "fastercsv"
require "lib/automater/point.rb"
require "lib/automater/cluster.rb"
require "lib/automater/kmean.rb"
require "pp"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace :mostfit do
  desc "Simulate the natural activity in a pattern"
  task :simulate do
    Merb.logger.info "Simulating the natural activity in a pattern"
    names = FasterCSV.parse(File.read("db/names.csv")).flatten
    len = names.length
    counter = 1
    user = User.first

    regions = FasterCSV.parse(File.read("db/in_lat_long.csv")).flatten
    nregions = regions.length/4

    areas = FasterCSV.parse(File.read("db/in_lat_long1.csv")).flatten
    nareas = areas.length/3

    dobs = FasterCSV.parse(File.read("db/date_of_births.csv")).flatten
    dob_len = dobs.length

    funders = FasterCSV.parse(File.read("db/funders.csv")).flatten
    funders.each{|f_name|
      funder = Funder.first(:name => f_name) || Funder.create(:name => f_name)
      funder.save unless funder.valid?
      (1..1+(rand()*4)).each {|x|
        funding_line = FundingLine.create(:funder => funder, :amount => x*100000, :interest_rate => 6+rand()*8, :disbursal_date => Date.today, :first_payment_date => Date.today+7, :last_payment_date => Date.today+365*5)
        funding_line.save unless funding_line.valid?
      }
    }

    fees = FasterCSV.parse(File.read("db/fees.csv")).flatten
    (0...fees.length/5).each {|i|
      fee = Fee.first(:name => fees[5*i], :percentage => fees[5*i+1].to_f) || Fee.create(:name => fees[5*i], :percentage => fees[5*i+1].to_f, :amount => fees[5*i+2].to_i, :min_amount => fees[5*i+3].to_i, :max_amount => fees[5*i+4].to_i, :payable_on => :loan_applied_on)
      fee.save unless fee.valid? 
    }

    cts = FasterCSV.parse(File.read("db/client_types.csv")).flatten
    cts.each{|type|
      client_type = ClientType.first(:type => type) || ClientType.create(:type => type)
      client_type.save unless client_type.valid?
    }

    lps = FasterCSV.parse(File.read("db/loan_products.csv")).flatten
    (0...lps.length/10).each {|i|
      if(Date.parse(lps[10*i+9])>Date.today)
        loan_product = LoanProduct.first(:name => lps[10*i]) || LoanProduct.create(:name => lps[10*i], :max_amount => lps[10*i+1].to_i, :min_amount => lps[10*i+2].to_i, :max_interest_rate => lps[10*i+3].to_f, :min_interest_rate => lps[10*i+4].to_f,
                                                                                   :installment_frequency => :weekly, :max_number_of_installments => lps[10*i+5].to_i, :min_number_of_installments => lps[10*i+6].to_i,
                                                                                   :loan_type => "DefaultLoan", :valid_from => Date.parse(lps[10*i+8]), :valid_upto => Date.parse(lps[10*i+9]))
        loan_product.errors {|e| puts e} 
        loan_product.save! unless loan_product.valid?
      end
    }

    occs = FasterCSV.parse(File.read("db/occupations.csv")).flatten
    occs.each {|occ|
      occupation = Occupation.first(:name => occ) || Occupation.create(:name => occ)
      occupation.save unless occupation.valid?
    }

    icompanies = FasterCSV.parse(File.read("db/insurance_companies.csv")).flatten
    icompanies.each {|company|
      insurance_company = InsuranceCompany.first(:name => company) || InsuranceCompany.create(:name => company)
      insurance_company.save unless insurance_company.valid?
    }

    iproducts = FasterCSV.parse(File.read("db/insurance_products.csv")).flatten
    (0...iproducts.length/2).each{|i|
      insurance_product = InsuranceProduct.first(:name => iproducts[2*i]) || InsuranceProduct.create(:name => iproducts[2*i], :insurance_company => InsuranceCompany.first(:name => "#{iproducts[2*i+1]}"))
      insurance_product.save unless insurance_product.valid?
    }

    if Region.all.empty?
      region_count, branch_count, center_count, ccount, n_center = 0, -1, 0, 0, 0
    else
      region_count = Region.count                  # total number of regions
      branch_count = Area.last.branches.count-1    # total number of branches in the last area - 1
      center_count = Branch.last.centers.count     # total number of centers in the last branch
      center_manager = Branch.last.centers.last.manager
      ccount = Region.last.areas.last.branches.count + Region.last.areas.last.branches.centers.count
      raw_data = FasterCSV.parse(File.read("db/in_lat_long#{regions[regions.index(Region.last.name)-1]}.csv")).flatten
      n_center = raw_data.length/3
      data = []
      (0...raw_data.length/3).each {|i|
        point = Point.new(raw_data[3*i], raw_data[3*i+1].to_f, raw_data[3*i+2].to_f)
        data.push(point)
      }
      clusters = kmeans(data, n_center/25 + 1, 10.0)
      clusters.each{|cluster| cluster.centerize}      
    end    
    
    c_date = Date.today
    c_time = Time.now
    count = 0
    DAYS = [:monday, :tuesday, :wednesday, :thursday, :friday]
    CASTES = ['sc', 'st', 'obc', 'general']
    RELIGIONS = ['hindu', 'muslim', 'sikh', 'jain', 'buddhist', 'christian']
    
    while true
      region = Region.last if !Region.nil?
      area = Area.last if !Area.nil?
      if ccount >=n_center
        ccount = 0
        raw_data = FasterCSV.parse(File.read("db/in_lat_long#{regions[4*region_count]}.csv")).flatten
        n_center = raw_data.length/3
        data = []
        (0...raw_data.length/3).each {|i|
          point = Point.new(raw_data[3*i], raw_data[3*i+1].to_f, raw_data[3*i+2].to_f)
          data.push(point)
        }
        clusters = kmeans(data, n_center/25 + 1, 10.0)
        clusters.each{|cluster| cluster.centerize}
    
        regional_manager = StaffMember.create(:name => names[(rand()*len).to_i], :active => true, :creation_date => c_date)
        region = Region.create(:manager => regional_manager, :name => regions[region_count*4+1], :creation_date => c_date)
        region.save

        region_location = Location.create(:parent_id => region.id, :parent_type => "region", :latitude => regions[region_count*4+2].to_f, :longitude => regions[region_count*4+3].to_f)
        region_location.save
        
        area_manager = StaffMember.create(:name => names[(rand()*len).to_i], :active => true, :creation_date => c_date)
        area = Area.create(:name => areas[region_count*3], :region => region, :manager => area_manager, :creation_date => c_date)
        area.save

        area_location = Location.create(:parent_id => area.id, :parent_type => "area", :latitude => areas[region_count*3+1].to_f, :longitude => areas[region_count*3+2].to_f)
        area_location.save

        region_count += 1
        branch_count = -1
      end

      if branch_count==-1 or Branch.last.centers.length>=clusters[branch_count].points.length
        branch_count += 1
        center_count = 0
        branch_manager = StaffMember.create(:name => names[(rand()*len).to_i], :active => true, :creation_date => c_date)
        branch = Branch.create(:name => clusters[branch_count].center.name, :code => "R#{region.id}A#{area.id}B#{branch_count}", :area => area,
                               :manager => branch_manager, :creation_date => c_date)
        branch.save
        ccount += 1

        branch_location = Location.create(:parent_id => branch.id, :parent_type => "branch", :latitude => clusters[branch_count].center.lat, :longitude => clusters[branch_count].center.long)
        branch_location.save

        if center_count%20==0
          center_manager = StaffMember.create(:name => names[(rand()*len).to_i], :active => true, :creation_date => c_date)
        end
        center = Center.create(:branch => branch, :manager => center_manager, :name => clusters[branch_count].points[center_count].name, :code => branch.code+"C#{center_count}",
                               :meeting_day => DAYS[center_count%5], :meeting_time_hours => "#{7+center_count%5}", :meeting_time_minutes => 0,
                               :creation_date => c_date)
        center.save!

        center_location = Location.create(:parent_id => center.id, :parent_type => "center", :latitude => clusters[branch_count].points[center_count].lat, :longitude => clusters[branch_count].points[center_count].long)
        center_location.save

        center_count = 1
        ccount = ccount + 1

        client_grp = ClientGroup.create(:name => "Group#{counter}", :code => "G#{counter}", :center => center)
        client_grp.save!
        
        joining_date = center.creation_date + rand()*30
        5.times{|x|
          client = Client.create(:name => names[counter%len], :reference => "#{branch.code}#{center.code}#{client_grp.code}#{x}", :center => center, :created_by => user,
                                 :created_by_staff => center.manager, :date_joined => joining_date, :client_type => ClientType.all[(rand()*(ClientType.count)).to_i],
                                 :client_group => client_grp, :date_of_birth => Date.parse(dobs[counter%dob_len]),
                                 :caste => CASTES[(rand()*CASTES.length).to_i], :religion => RELIGIONS[(rand()*RELIGIONS.length).to_i])
          client.save

          counter = counter + 1
          date = client.date_joined + (rand()*10).to_i
          loan_pro = LoanProduct.all[(rand()*LoanProduct.count).to_i]
          amt = loan_pro.min_amount + (rand()*((loan_pro.max_amount-loan_pro.min_amount)/1000)).to_i*1000
          int_rate = (loan_pro.min_interest_rate + rand()*(loan_pro.max_interest_rate-loan_pro.min_interest_rate))/100
          ninstallments = loan_pro.min_number_of_installments + (rand()*((loan_pro.max_number_of_installments-loan_pro.min_number_of_installments))).to_i
          loan = DefaultLoan.create(:amount => amt, :amount_applied_for => amt, :amount_sanctioned => amt, :interest_rate => int_rate, :discriminator => DefaultLoan,
                                    :installment_frequency => :weekly, :funding_line => FundingLine.all[(rand()*(FundingLine.count)).to_i], :loan_product => loan_pro,
                                    :number_of_installments => ninstallments, :scheduled_disbursal_date => date+7, :scheduled_first_payment_date => date+14,
                                    :applied_on => date, :approved_on => date+3, :disbursal_date => date+7, :applied_by => center.manager, :created_by => user,
                                    :approved_by => center.branch.manager, :disbursed_by => center.manager, :client => client, :occupation => Occupation.all[(rand()*Occupation.count).to_i])
          loan.save unless loan.valid?
        }
      else
        branch = Branch.last
        if branch.centers.last.creation_date+14 <= c_date
          if center_count%20==0
            center_manager = StaffMember.create(:name => "R#{region.id}A#{area.id}B#{branch.id} Cen#{center_count} Manager", :active => true, :creation_date => c_date)
            center_manager.save!
          end
          center = Center.create(:branch => branch, :manager => center_manager, :name => clusters[branch_count].points[center_count].name, :code => branch.code+"C#{center_count}",
                                 :meeting_day => DAYS[center_count%5], :meeting_time_hours => "#{7+center_count%5}", :meeting_time_minutes => 0,
                                 :creation_date => c_date)
          center.save
          
          center_location = Location.create(:parent_id => center.id, :parent_type => "center", :latitude => clusters[branch_count].points[center_count].lat, :longitude => clusters[branch_count].points[center_count].long)
          center_location.save
          center_count = center_count+1  
          ccount = count + 1
          center.save!
        end

        Branch.last.centers(:creation_date.gt => c_date-49).each {|center|
          if (c_date-center.creation_date).to_i%7==0
            client_grp = ClientGroup.create(:name => "Group#{counter}", :code => counter, :center => center)
            client_grp.save

            joining_date = center.creation_date + rand()*30
            5.times{|x|
              client = Client.create(:name => names[counter%len], :reference => "#{branch.code}#{center.code}#{client_grp.code}#{x}", :center => center,
                                     :created_by => user, :created_by_staff => center.manager, :date_joined => joining_date,
                                     :client_type => ClientType.all[(rand()*(ClientType.count-1)).to_i], :client_group => client_grp, :date_of_birth => Date.parse(dobs[counter%dob_len]),
                                     :caste => CASTES[(rand()*CASTES.length).to_i], :religion => RELIGIONS[(rand()*RELIGIONS.length).to_i])
              client.save
              counter = counter + 1
              date = client.date_joined + (rand()*10).to_i
              loan_pro = LoanProduct.all[(rand()*LoanProduct.count).to_i]
              amt = loan_pro.min_amount + (rand()*((loan_pro.max_amount-loan_pro.min_amount)/1000)).to_i*1000
              int_rate = (loan_pro.min_interest_rate + rand()*(loan_pro.max_interest_rate-loan_pro.min_interest_rate))/100
              ninstallments = loan_pro.min_number_of_installments + (rand()*((loan_pro.max_number_of_installments-loan_pro.min_number_of_installments))).to_i
              loan = DefaultLoan.create(:amount => amt, :amount_applied_for => amt, :amount_sanctioned => amt, :interest_rate => int_rate, :discriminator => DefaultLoan,
                                        :installment_frequency => :weekly, :funding_line => FundingLine.all[(rand()*(FundingLine.count)).to_i], :loan_product => loan_pro,
                                        :number_of_installments => ninstallments, :scheduled_disbursal_date => date+7, :scheduled_first_payment_date => date+14,
                                        :applied_on => date, :approved_on => date+3, :disbursal_date => date+7, :applied_by => center.manager, :created_by => user,
                                        :approved_by => center.branch.manager, :disbursed_by => center.manager, :client => client, :occupation => Occupation.all[(rand()*Occupation.count).to_i])
              loan.save unless loan.valid?
            }
            center.save
            branch.save
          end
        }
      end

      LoanHistory.all(:date => c_date, :status => :outstanding, :principal_due.gt => 0).each {|loan_his|
        loan = loan_his.loan
        loan.payment_schedule.find_all{|pay| pay[0]==c_date}.each{|pay|
          loan.repay(pay[1][:principal]+pay[1][:interest], User.first, c_date, loan.client.client_group.center.manager, false, NORMAL_REPAYMENT_STYLE, :default)
        }
      }

      count = count+1
      c_time = c_time + 86400
      c_date = Date.new(c_time.year, c_time.month, c_time.day) 
      Merb.logger.info "Current date -> #{c_date}\nNumber of regions -> #{Region.count}\nNumber of areas -> #{Area.count}\nNumber of branches -> #{Branch.count}\nNumber of centers -> #{Center.count}\nNumber of ClientGruops -> #{ClientGroup.count}\nNumber of Clients -> #{Client.count}\nNumber of loans -> #{Loan.count}\nNumber of payments made -> #{Payment.count}\nIteration count -> #{count}"
      Merb.logger.info "========================================================================================================================================================="
      sleep(86400)
    end
  end
end

