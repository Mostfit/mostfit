require "rubygems"

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

def load_fixtures(*files)
  files.each do |name|
    klass = Kernel::const_get(name.to_s.singularize.camel_case)
    yml_file =  "spec/fixtures/#{name}.yml"
    puts "\nLoading: #{yml_file}"
    entries = YAML::load_file(Merb.root / yml_file)
    entries.each do |name, entry|
      k = klass::new(entry)
      puts "#{k} :#{name}"

      if k.class == Loan  # do not update the hisotry for loans
        k.history_disabled = true
      end
      unless k.save
        puts "Validation errors saving a #{klass} (##{k.id}):"
        p k.errors
        raise
      end
    end
  end
end



namespace :mostfit do
  namespace :mock do
    desc "All in one -- load fixtures, generate payments and update the history"
    task :load_demo do
      Rake::Task['mock:fixtures'].invoke
      Rake::Task['mock:all_payments'].invoke
      Rake::Task['mock:update_history'].invoke
      puts
      puts "If all went well your demo environment has been loaded/generated... Enjoy the sandbox!"
    end

    desc "Drop current db and load fixtures from /spec/fixtures (and work the update_history jobs down)"
    task :fixtures do
      DataMapper.auto_migrate! if Merb.orm == :datamapper
      # loading is ordered, important for our references to work
      load_fixtures :users, :staff_members, :funders, :funding_lines, :branches, :centers, :clients, :loan_products, :loans  #, :payments
      puts
      puts "Fixtures loaded. Have a look at the mock:all_payments and mock:update_history tasks."
    end

    desc "will make 200K loans in 10K Centers and 200 Branches"
    task :massive_db do
      DataMapper.auto_migrate! if Merb.orm == :datamapper

      f = Funder.new(:name => 'icicicici')
      f.save
      fl = FundingLine.new(:funder => f, :amount =>10000000, :interest_rate => 0.12,
                           :disbursal_date => Date.parse('2008-01-01'),
                           :first_payment_date => Date.parse('2008-07-01'),
                           :last_payment_date => Date.parse('2010-01-01'))
      if not fl.save
        fl.errors.each do |e|
          puts e
        end
        raise
      end
      #first make the branches
      25.times do |i|
        sm = StaffMember.new(:name => "Branch Manager #{i}" )
        sm.save
        puts "staff_member => #{i}"
        b = Branch.new(:name => "Branch #{i}")
        b.manager = sm
        b.save
        puts "branch => #{i}"
        # make 20 random center managers
        cms = []
        20.times do |j|
          cm = StaffMember.new(:name => "br #{i} cm #{j}")
          cm.save
          cms << cm
          puts "center_manager => #{cm.name}"
        end
        # make 400 centers per branch
        400.times do |j|
          md = Center.meeting_days[[1,rand(7)].min]

          center = Center.new(:branch => b, :name => "br #{i} cen #{j}",
                              :manager => cms[rand(20)],
                              :meeting_day => Center.meeting_days[rand(7)])
          center.save
          puts "center #{center.name} : manager => #{center.manager.name}"
        end
      end
    end

    desc "makes clients and loans for massive_db"
    task :massive_clients do
      #make 20 clients per center and their loans
      d1 = Date.parse('2008-08-01')
      d2 = Date.parse('2009-06-01')
      fl = FundingLine.get 1
      cids = Center.all.map { |c| c.id}
      cids.each do |cid|
        center = Center.get(cid)
        next if center.clients.size == 20
        i = center.branch.id
        b = center.branch
        j = center.id
        date_joined = nil
        client_sql = %Q{INSERT INTO clients (name, date_joined, reference, center_id) VALUES }
        loan_sql = %Q{ INSERT INTO loans (client_id, amount, interest_rate, installment_frequency, number_of_installments,
                                   applied_on, applied_by_staff_id, approved_on, approved_by_staff_id,
                                   scheduled_disbursal_date, scheduled_first_payment_date,
                                   disbursed_by_staff_id, disbursal_date,
                                   funding_line_id, discriminator) VALUES }
        values = []
        (20 - center.clients.size).times do |k|
          date_joined = (d1..d2).sort_by{rand}[0]
          value = "('br #{i} cen #{j} cl #{k}', '#{date_joined}', '#{i}-#{j}-#{k}', #{j})"
          values << value
        end
        sql = client_sql + values.join(",")
        repository.adapter.execute(sql)
        puts "Added 20 clients to center no #{j} in branch #{i}"
        values = []
        Client.all(:center_id => j).each do |cl|
          applied_on = center.next_meeting_date_from(date_joined)
          approved_on = applied_on + 2
          scheduled_disbursal_date = center.next_meeting_date_from(applied_on)
          scheduled_first_payment_date = center.next_meeting_date_from(scheduled_disbursal_date)
          disbursal_date = scheduled_disbursal_date
          value = %Q{(#{cl.id}, 8000, 0.18, 2, 50, '#{applied_on}', #{center.manager.id}, '#{approved_on}', #{b.manager.id},
                   '#{scheduled_disbursal_date}', '#{scheduled_first_payment_date}',  #{center.manager.id}, '#{disbursal_date}', #{fl.id}, 'Loan')}
          values << value
        end
        sql = loan_sql + values.join(",")
        repository.adapter.execute(sql)
      end
    end

    desc "Generate all payments for all loans without payments as if everyone paid dilligently (does not write any history)"
    task :all_payments do
      puts "starting"
      t0 = Time.now
      Merb.logger.info! "Start mock:all_payments rake task at #{t0}"
      busy_user = User.get(1)
      count = 0
      if 1 #Payment.all.empty?
        loan_ids = repository.adapter.query("SELECT id from loans WHERE deleted_at IS NULL")
      else
        loan_ids = repository.adapter.query("SELECT id from loans WHERE id > (select max(loan_id) from payments) AND deleted_at IS NULL")
      end
      puts "1: #{Time.now - t0}"
      loan_ids.each do |loan_id|
        sql = " INSERT INTO `payments` (`received_by_staff_id`, `amount`, `type`, `created_by_user_id`, `loan_id`, `received_on`, `client_id`) VALUES ";
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
          values << "(#{staff_member.id}, #{prin}, 1, 1, #{loan.id}, '#{date}', #{loan.client.id})"
          values << "(#{staff_member.id}, #{int}, 2, 1, #{loan.id}, '#{date}', #{loan.client.id})"
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
      Merb.logger.info! "Finished mock:all_payments rake task in #{secs} secs for #{Loan.all.size} loans creating #{count} payments, at #{t1}"
    end

    desc "Recreate the whole history"
    task :update_history do
      log = File.open(Merb.root + "/log/update_history.log","w")
      t0 = Time.now
      Merb.logger.info! "Start mock:history rake task at #{t0}"
      puts "finding unhistorified loans"
      if LoanHistory.all.count == 0
        loan_ids = repository.adapter.query("SELECT id from loans")
      else
        loan_ids = repository.adapter.query("SELECT id from loans WHERE id > (select max(loan_id) from loan_history)")
      end
      puts "got loan ids"
      if loan_ids.empty?
        puts "loan_ids empty. getting all"
        loan_ids = repository.adapter.query("SELECT id from loans")
      end
      t0 = Time.now
      co = loan_ids.count
      loan_ids.each_with_index do |loan_id, idx|
        loan = Loan.get(loan_id)
        next unless loan
        loan.update_history_bulk_insert
        status_line = "Did loan #{loan.id} (#{idx}/#{co} or #{idx/co.to_f*100.round(2)}%) in #{Time.now - t0} secs)\n"
        log.write status_line
        print status_line if idx%50 == 0
      end
      t1 = Time.now
      secs = (t1 - t0).round
      Merb.logger.info! "Finished mock:history rake task in #{secs} secs for #{Loan.all.size} loans with #{Payment.all.size} payments, at #{t1}"
      log.close
    end

    desc "Recreate all history"
    task :update_all_history do
      t0 = Time.now
      Merb.logger.info! "Start mock:history rake task at #{t0}"
      loan_ids = repository.adapter.query("SELECT id from loans")
      t0 = Time.now
      loan_ids.each do |loan_id|
        loan = Loan.get(loan_id)
        loan.update_history
      end
      t1 = Time.now
      secs = (t1 - t0).round
      Merb.logger.info! "Finished mock:history rake task in #{secs} secs for #{Loan.all.size} loans with #{Payment.all.size} payments, at #{t1}"
    end

    desc "Historify unhistorified loans"
    task :historify_unhistorified do
      t0 = Time.now
      Merb.logger.info! "Start mock:history rake task at #{t0}"
      Loan.all.each do |l|
        l.update_history if l.loan_history.blank?
      end
      t1 = Time.now
      secs = (t1 - t0).round
      Merb.logger.info! "Finished mock:history rake task in #{secs} secs for #{Loan.all.size} loans with #{Payment.all.size} payments, at #{t1}"
    end

    task :add_date_joined do
      cs = Client.all(:date_joined => nil).map{|c| c.id}
      cs.each do |id|
        c = Client.get(id)
        print "Doing client id #{c.id}..."
        c.date_joined = c.loans[0].applied_on - 1
        c.save
        print ".done \n"
      end
    end
  end
end




# some fixture loader if found online, more features, none we need so far it seems...
# # $map = Hash.new
# #
# # path = Merb.root / "spec" / "fixtures"
# # files = ["users", "news_items", "privs"]
# # files.reverse.each { |f| f.classify.constantize.create_table! }
# # files.map! { |f| (path / f) + ".yml" }
# #
# # files.each do |path|
# #   puts "Processing #{path}"
# #   fixtures = YAML::load_file(path) || {}
# #   klass = File.basename(path, ".yml")
# #   klass = klass.classify.constantize
# #   fixtures.each do |name, attributes|
# #     attributes.each_pair do |key, value|
# #       if value =~ /^@/
# #         methods = value[1 .. -1].split(".")
# #         m = methods.shift
# #         value = $map[m]
# #         raise "Value is nil for key '#{m}'" if value.nil?
# #         value = value.send(methods.shift) while !methods.empty?
# #         attributes[key] = value
# #       end
# #     end
# #     object = klass.new(attributes)
# #     raise "Object invalid: #{object.inspect}\n#{object.errors.inspect}" unless object.valid?
# #     object.save
# #     raise "Key '#{name}' already exists!" if $map[name]
# #     $map[name] = object
# #   end
# # end
