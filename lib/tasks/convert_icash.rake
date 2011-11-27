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
  namespace :conversion do
    desc "convert intellecash db to takeover-intellecash"
    task :convert_icash do
      puts "upgrading"
      Rake::Task['db:autoupgrade'].invoke
      # add repayment styles to loan products
      LoanProduct.all(:id => [1,2,3,4]).each{|lp| lp.repayment_style = RepaymentStyle.get(3); lp.save}
      LoanProduct.all(:id => 5..10).each{|lp| lp.repayment_style = RepaymentStyle.get(1); lp.save}
      LoanProduct.all(:id => [11,12,13]).each{|lp| lp.repayment_style = RepaymentStyle.get(2); lp.save}

      # update the center_meeting_days for the Dairy Loan centers
      dcs = Center.all(:name.like => "%Dairy%")
      cmds = CenterMeetingDay.all(:center => dcs)
      cmds.each do |cmd|
        cmd.update(:every => "1", :what => cmd.meeting_day.to_s, :of_every => 2, :period => :week)
      end
      puts "done with normal stuff"
      # run the standard conversion script
      #repository.adapter.execute('update loans set discriminator="Loan"')
      #repository.adapter.execute('alter table loan_history drop column scheduled_principal_to_be_paid')
      #repository.adapter.execute('alter table loan_history drop column scheduled_interest_to_be_paid')
      Rake::Task['mostfit:conversion:to_new_layout'].invoke
    end
  end
end
