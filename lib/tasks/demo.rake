# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')


namespace :mostfit do
  namespace :demo do
    desc "randomly pay centers"
    task :randomly_pay_centers do
      date = Date.today
      centers = LoanHistory.all(:date => date).aggregate(:center_id)
      s = StaffMember.all(:active => true).first
      u = User.first
      while true
        id = centers[(rand * centers.count).to_i]
        center = Center.get(id)
        unless center
          puts "no center with id #{id}...skipping"
          next
        else
          branch = center.branch
          lhs = LoanHistory.all(:center_id => id, :date => date).aggregate(:loan_id, :principal_due, :interest_due)
          puts "doing center #{id}. #{lhs.count} loans: BRANCH #{branch.name}"
          lhs.each_with_index do |lh, i|
            t = Time.now
            l = Loan.get(lh[0])
            next unless l
            amount = lh[1] + lh[2]
            print "\t repaying loan id #{l.id} (#{i}/#{lhs.count}) with amount #{amount}..."
            begin
              l.repay(amount, u, date, s, false, PRORATA_REPAYMENT_STYLE)
              print "...done  (#{(Time.now - t).round} secs)\n"
            rescue
              print "....FAILED!"
            end
          end
        end
      end
    end
  end
end
