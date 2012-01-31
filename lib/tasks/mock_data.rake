require "rubygems"

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  namespace :data do
    desc "Generate all payments for all loans without payments as if everyone paid dilligently (does not write any history)"
    task :all_payments do
      puts "starting"
      t0 = Time.now
      Merb.logger.info! "Start mock:all_payments rake task at #{t0}"
      busy_user = User.get(1)
      count = 0
      if Payment.all.empty?
        loan_ids = repository.adapter.query("SELECT id from loans WHERE deleted_at IS NULL")
      else
        loan_ids = repository.adapter.query("SELECT id from loans WHERE id > (select max(loan_id) from payments) AND deleted_at IS NULL")
      end
      puts "1: #{Time.now - t0}"
      loan_ids.each do |loan_id|
        sql = " INSERT INTO `payments` (`received_by_staff_id`, `amount`, `type`, `created_by_user_id`, `loan_id`, `received_on`, `client_id`, `c_branch_id`, `c_center_id`) VALUES ";
        _t0 = Time.now
        loan = Loan.get(loan_id)
        staff_member = loan.client.center.manager
        p "Doing loan No. #{loan.id}...."
        loan.history_disabled = true  # do not update the hisotry for every payment
        dates      = loan.installment_dates.reject { |x| x > Date.today or x < loan.disbursal_date }
        values = []
        dates.each do |date|
          prin = loan.scheduled_principal_for_installment(loan.installment_for_date(date))
          int = loan.scheduled_interest_for_installment(loan.installment_for_date(date))
          values << "(#{staff_member.id}, #{prin}, 1, 1, #{loan.id}, '#{date}', #{loan.client.id}, #{loan.c_branch_id}, #{loan.c_center_id})"
          values << "(#{staff_member.id}, #{int}, 2, 1, #{loan.id}, '#{date}', #{loan.client.id}, #{loan.c_branch_id}, #{loan.c_center_id})"
          count += 1
        end
        puts "done constructing sql in #{Time.now - _t0}"
        if not values.empty?
          sql += values.join(",")
          repository.adapter.execute(sql)
          puts "done executing sql in #{Time.now - _t0}"
          puts "---------------------"
        end
        p "done in #{Time.now - _t0} secs. Total time: #{Time.now - t0} secs"
      end
      #    end
      t1 = Time.now
      secs = (t1 - t0).round
      #for updating history of all loans.
      Loan.all.each do |l|
        l.update_history
      end
      Merb.logger.info! "Finished mock:all_payments rake task in #{secs} secs for #{Loan.all.size} loans creating #{count} payments, at #{t1}"
    end

    desc "Clear loan_history table"
    task :clear_history do
      puts "truncating loan_history table"
      repository.adapter.execute("truncate table loan_history;")
    end

    desc "Update missing loan_histories"
    task :create_history do
      t0 = Time.now
      puts "finding unhistorified loans"
      lids = Loan.all.aggregate(:id)
      hids = LoanHistory.all.aggregate(:loan_id)
      loan_ids = lids - hids
      puts "got loan ids"
      t0 = Time.now
      co = loan_ids.count
      loan_ids.each_with_index do |loan_id, idx|
        begin
          loan = Loan.get(loan_id)
          next unless loan
          loan.update_history
          print "."
        rescue
          print "!"
          puts loan_id
        end
        pdone = (idx + 1)/co.to_f
        elapsed = (Time.now - t0).round
        avg_s_per_loan = (elapsed.to_f/(idx + 1)).round(2)
        status_line = "\n#{idx}/#{co} or #{(pdone*100).round(2)}% in #{elapsed} secs ETA #{(avg_s_per_loan * (co - idx) / 60).round(2)} mins: Avg #{avg_s_per_loan} s/loan\n"
        print status_line if idx%50 == 0
      end
      t1 = Time.now
      secs = (t1 - t0).round
      Merb.logger.info! "Finished mock:history rake task in #{secs} secs for #{Loan.all.size} loans with #{Payment.all.size} payments, at #{t1}"
     # log.close
    end

    desc "big database"
    task :big, :centers_with do |task, args|
      # `bin/slurp.rb spec/fixtures/big.sql`

      # create branches
      if Branch.all.count == 0
        branches = YAML::load_file('spec/districts.yml').uniq
        r = branches[0..500].map do |b|
          puts "creating branch #{b}"
          br = Branch.new(:name => b, :manager => StaffMember.all[rand(StaffMember.all.count - 1)], :code => b[0..8])
          br.creation_date = Date.new([2010,2011][rand(2)], (1..12).to_a[rand(12)], (1..25).to_a[rand(25)])
          [br.save, br]
        end
        if r.map{|_r| _r[0]}.include?(false) # something went wrong
          puts r[0][0].errors
          raise
        end
      end
      # create centers
      branch_count = Branch.all.count
      if branch_count < 499
        Branch.all.each_with_index do |b,bi|
          if b.centers.count < 40
            (b.centers.count..40).each do |i|
              print(".".green)
              c = Center.new(:name => "#{b.name} center #{i}", :creation_date => b.creation_date + (7 * (i/8.0).ceil),
                             :manager => StaffMember.all[rand(StaffMember.count - 1)])
              c.code = "#{b.id}.#{i}"
              c.meeting_day = WEEKDAYS[rand(7)]
              c.meeting_time_hours = [8,9,10,11,12,13,14,15,16][rand(8)]
              c.meeting_time_minutes = [0,15,30,45][rand(3)]
              c.branch  = b
              c.save
            end
          end
          print " #{bi}/#{branch_count}\n"
        end
      end
      # create clients
      puts "reading clients.yml"
      client_names = YAML::load_file('spec/names.yml')
      u = User.first
      center_count = Center.all.count
      t = Time.now
      Center.all(:id.gt => 100000).each_with_index do |cn, icn|
        print "#{cn.name} #{icn}/#{center_count}"
        # add five clients a week for five weeks
        d0      = cn.creation_date
        manager = cn.manager
        (1..5).each do |i|
          d = d0 + (i * 7)
          (1..5).each do |j|
            print ".".green
            cl = Client.new(:name => client_names[rand(client_names.size - 1)],
                            :date_joined => d,
                            :reference => "#{cn.id}:#{i}.#{j}",
                            :created_by => u,
                            :created_by_staff => manager,
                            :center => cn)
            cl.save rescue puts ".".red
          end
        end
        elapsed = Time.now - t
        eta = (center_count - icn) * elapsed / icn.to_f / 60
        puts "elapsed: #{elapsed}. eta: #{eta}"
      end

      # create loans
      
      puts "adding loans"
      t = Time.now
      client_count = Client.all.count
      current = 1
      centers = args[:centers_with] ? Center.all(:name.like => "#{args[:centers_with]}%") : Center.all
      centers.aggregate(:id).each do |cid|
        center = Center.get(cid)
        if center.loans.count > 0
          current += center.loans.count
          next
        end
        print center.name
        manager = center.manager
        branch_manager = center.branch.manager
        funding_line = FundingLine.all[rand(FundingLine.count - 1)]
        clients = Client.all(:center_id => cid)
        lp = LoanProduct.all[rand(LoanProduct.all.count - 1)] # same loan product for all
        clients.each do |c|
          mdates = center.get_meeting_dates(3,c.date_joined)
          scheduled_disbursal_date = mdates[-2]
          l = Loan.new(:amount => lp.min_amount, :interest_rate => lp.min_interest_rate/100, :loan_product => lp,
                       :applied_on => c.date_joined, :approved_on => c.date_joined+1, :applied_by => center.manager, :created_by => User.first, 
                       :approved_by => branch_manager,
                       :scheduled_disbursal_date => scheduled_disbursal_date, 
                       :scheduled_first_payment_date => mdates[-1],
                       :disbursal_date => scheduled_disbursal_date, :disbursed_by => manager,
                       :funding_line => funding_line, :client => c)
          unless l.valid?
            puts l.errors.values.join("::")
            raise
          else
            l.save
            print ".".green
            current += 1
          end
        end
        elapsed = (Time.now - t).round(2)
        eta = (((current / elapsed.to_f * client_count) / 60) / 60).round(2)
        puts "elapsed: #{(elapsed.to_f/60).round(2)} mins. eta: #{eta} mins"
      end
            
                       
    end
      

  end
end




