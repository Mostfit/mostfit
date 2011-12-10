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
    task :convert_sahayog do
      puts "upgrading"
      repository.adapter.execute("drop table loan_history")
      Rake::Task['db:autoupgrade'].invoke
      puts "done"
      # add repayment styles to loan products

      # update the center_meeting_days for specified centers
      dcs = Center.all(:id => [1642,1675,1676,1120,1121,1122])
      dcs.each do |c|
        cmd = CenterMeetingDay.all(:center => c).last
        cmd.update(:every => "1", :what => cmd.meeting_day.to_s, :of_every => 1, :period => :week, :valid_from => cmd.valid_from + 1)
      end
      puts "done with normal stuff"
      # run the standard conversion script
      repository.adapter.execute("update loans set discriminator='Loan'")
      repository.adapter.execute('alter table loan_history drop column scheduled_principal_to_be_paid') rescue nil
      repository.adapter.execute('alter table loan_history drop column scheduled_interest_to_be_paid') rescue nil
      Rake::Task['mostfit:conversion:to_new_layout'].invoke
    end
  end
end
