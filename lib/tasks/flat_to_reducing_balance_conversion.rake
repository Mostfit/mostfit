require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  namespace :conversion do
    task :prepare_db do
      Rake::Task['db:autoupgrade'].invoke
      puts "modifying loan_history table..."
      repository.adapter.execute("alter table loan_history modify scheduled_outstanding_principal float not null, modify scheduled_outstanding_total float not null, modify actual_outstanding_principal float not null, modify actual_outstanding_total float not null, modify principal_due float not null, modify interest_due float not null, modify principal_paid float not null, modify interest_paid float not null;")
      puts "modifying payments table.."
      repository.adapter.execute('alter table payments modify amount float not null;')
      Rake::Task['mostfit:conversion:update_loan_cache']
      i = 0    #increment operator for intrest_rate array.
      #updating all the loan_products.
      
      loan_product_id = [2, 3, 9, 10, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
      interest_rate = [29.2501, 31.744, 31.504, 31.02, 31.504, 14.67, 28.74, 12.01, 15.70, 26.89, 12.88, 17.49, 30.04, 11.79, 15.56, 26.76]
      LoanProduct.all(:id => loan_product_id).each{|lp|
        puts i
        puts lp.id
        lp.min_interest_rate = 0
        lp.max_interest_rate = 100
        i += 1      #increment operator to get next interest_rate for next loan_product_id.
        lp.save!
        puts "next loan product"
        puts i
      }

      StaffMember.all(:active => false).each{|sm| sm.active = true; sm.save}
      User.all(:active => false).each{|sm| sm.active = true; sm.save}
      repository.adapter.execute('update loans set discriminator="Loan";')

    end

    task :add_maturity_dates do
      Branch.all.each do |branch|
        puts "starting branch #{branch.name}"
        branch.centers.clients.loans(:_scheduled_maturity_date => nil).each do |l|
          l._scheduled_maturity_date = l.scheduled_maturity_date
          l.history_disabled = true
          l.save
          puts l.id
        end
        puts "done branch #{branch.name}"
      end
    end

    desc "run convert script for all branches"
    task :convert_all_branches do
      Branch.all.aggregate(:id).each do |branch_id|
        puts "-------------------------------------"
        puts "Doing branch #{branch_id}"
        Rake::Task["mostfit:conversion:f2ew"].execute(:branch_id => branch_id)
        #Rake::Task["mostfit:conversion:print_branch"].execute(:branch_id => branch_id)
      end
    end
    


    desc "convert using repayment_styles"
    task :f2ew, :branch_id, :loan_id do |task, args|
      @failures = File.open("tmp/failures_#{args[:branch_id]}", "w")
      @log = File.open("tmp/conversion_log_#{args[:brnch_id]}","w")
      loan_product_id = [2, 3, 9, 10, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
      d = Date.new(2011,3,31)
      if args.is_a? Rake::TaskArguments or args.is_a? Hash
        loans = (not args[:branch_id].blank?) ? Branch.get(args[:branch_id]).centers.clients.loans(:loan_product_id => loan_product_id, :c_scheduled_maturity_date.gt => d, :converted => false) : (args[:loan_id] ? Loan.all(:id => args[:loan_id]) : [])
      elsif args.is_a? Fixnum
        loans = Branch.get(args).centers.clients.loans(:loan_product_id => loan_product_id, :c_scheduled_maturity_date.gt => d, :converted => false)
      elsif args.is_a? Array
        loans = Loan.all(:id => args, :loan_product_id => loan_product_id, :c_scheduled_maturity_date.gt => d, :converted => false)
      else
        loans = []
      end
      # loans = Loan.all(:id => [3378, 5782, 3815, 3817, 3818, 3819, 4770, 4811, 3820, 7259, 3383, 3188, 3550])
      interest_rate = [29.2501, 31.744, 31.504, 31.7164, 31.504, 29.3399, 28.74, 12.01, 15.70, 26.89, 12.88, 17.49, 30.04, 11.79, 15.56, 26.76]
      h = loan_product_id.zip(interest_rate).to_hash

      count = loans.count
      curr = 0
      loans.each do |l|
        curr += 1
        begin        
          t0 = Time.now
          old_prin = old_int = new_prin = new_int = 0
          pmt = l.scheduled_principal_for_installment(1) + l.scheduled_interest_for_installment(1)
          int_rate = (h[l.loan_product_id]/100)/ l.send(:get_divider)
          curr_cf = {}
          ph = l.payments(:type => [:principal, :interest]).group_by{|p| p.received_on}.to_hash
          next if ph.empty?
          sql = "INSERT INTO payments(loan_id, type, received_on, created_at, client_id, received_by_staff_id, created_by_user_id, amount) values ("
          values = []
          curr_bal = l.amount
          ph.keys.sort.each_with_index do |date, i|
            debugger if date == Date.new(2010,11,02)
            prins = ph[date].select{|p| p.type == :principal}
            ints = ph[date].select{|p| p.type == :interest}
            p_amt = prins.reduce(0){|s,p| s + p.amount} || 0
            i_amt = ints.reduce(0){|s,p| s + p.amount} || 0
            total_amt = p_amt + i_amt
            old_prin += p_amt
            old_int += i_amt
            amt = total_amt
            int_pmt = prin_pmt = 0
            while (amt > 0 and curr_bal > 0)
              _ipmt = [amt, curr_bal * int_rate].min
              int_pmt += _ipmt
              amt -= _ipmt
              _ppmt = [amt, curr_bal, pmt - _ipmt].min
              prin_pmt += _ppmt
              amt -= _ppmt
              curr_bal -= _ppmt
            end
            me = ph[date][0]
            new_prin += prin_pmt
            new_int += int_pmt
            # puts "#{date} #{i} #{curr_bal} [#{p_amt}, #{i_amt}] => [#{prin_pmt}, #{int_pmt}]"
            [prin_pmt, int_pmt].each_with_index do |a,i|
              vals = [me.loan_id, i + 1, "'#{me.received_on.strftime('%Y-%m-%d')}'" , 
                    "'#{DateTime.now.strftime("%Y-%m-%d %H:%M:%S")}'", me.client_id, me.received_by_staff_id, me.created_by_user_id]
              val_string = vals.push(a).join(",")
              values.push(val_string)
            end
            curr_cf[date] = [int_pmt, prin_pmt, curr_bal]
          end
          old_total = old_prin + old_int
          new_total = new_prin + new_int
          if (old_total - new_total).abs > 10
            s = "*#{l.id}: #{Time.now - t0} (#{curr}/#{count}).[#{old_prin.round(2)}+#{old_int.round(2)}=#{old_total.round(2)}] => [#{new_prin.round(2)}+#{new_int.round(2)}=#{new_total.round(2)}]\n"
            puts s
            @failures.write("#{l.id} - total mismatch\n")
            next
          end
          sql += values.join("),(")
          sql += ")"
          discriminator = l.discriminator == "DefaultLoan" ?  "EquatedWeekly" : "EquatedWeeklyRoundedAdjustedLastPayment"
          repository.adapter.execute("update loans set discriminator='#{discriminator}' where id = #{l.id}")
          l = Loan.get(l.id)
          h = loan_product_id.zip(interest_rate).to_hash
          l.interest_rate = h[l.loan_product_id]/100
          l.converted = true
          l.save!
          repository.adapter.execute("delete from payments where loan_id = #{l.id} and type in (1,2)")
          repository.adapter.execute(sql)
          l.update_history(true)
          s = "#{l.id} #{Time.now - t0} (#{curr}/#{count})\n"
          @log.write(s)
          puts s
        rescue => e
          puts e
          @failures.write("#{l.id}\n")
          puts "#{l.id} failed! (#{curr}/#{count})"
         end
      end
      @failures.close
      @log.close
    end


    desc "print all branch ceonversion results"
    task :print_results do
      Branch.all.aggregate(:id).each do |id|
        Rake::Task['mostfit:conversion:print_branch'].execute(id)
      end
    end

    desc "prints out conversion stats per branch for quick comparison"
    task :print_branch, :branch_id do |task, args|
      @file = File.new("tmp/branch_#{args}", "w")
      puts "doing branch #{args}"
      Branch.get(args).centers.each do |center|
        center.clients.loans.each do |l| 
          payments_recd_on_loan = loan.payments(:type => [:principal, :interest]).aggregate(:amount.sum)
          repaid_loan_balance =  l.c_scheduled_maturity_date < Date.today ? LoanHistory.first(:loan_id => l.id, :date => l.c_scheduled_maturity_date).actual_outstanding_balance : 0
          @file.write "#{l.id} : #{l.payments_recd_on_loan} : #{repaid_loan_balance}\n"
        end
      end
      @file.close
    end


  end
end
