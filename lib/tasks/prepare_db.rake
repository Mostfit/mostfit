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
  namespace :db do
    desc "populate the database using the csv's"
    task :prepare do
      repository.adapter.execute(%Q{
         alter table loan_history modify actual_outstanding_total decimal(10,2) not null, 
                             modify scheduled_outstanding_total decimal(10,2) not null,
                             modify actual_outstanding_principal decimal(10,2) not null,
                             modify scheduled_outstanding_principal decimal(10,2) not null,
                             modify scheduled_principal_due decimal(10,2) not null,
                             modify scheduled_interest_due  decimal(10,2) not null,
                             modify principal_due  decimal(10,2) not null,
                             modify interest_due decimal(10,2) not null,
                             modify principal_paid  decimal(10,2) not null,
                             modify interest_paid  decimal(10,2) not null,
                             modify total_interest_due  decimal(10,2) not null,
                             modify total_principal_due  decimal(10,2) not null,
                             modify total_principal_paid  decimal(10,2) not null,
                             modify total_interest_paid  decimal(10,2) not null,
                             modify advance_principal_paid decimal(10,2) not null,
                             modify advance_interest_paid  decimal(10,2) not null,
                             modify advance_principal_adjusted  decimal(10,2) not null,
                             modify advance_interest_adjusted   decimal(10,2) not null,
                             modify principal_in_default        decimal(10,2) not null,
                             modify interest_in_default         decimal(10,2) not null,
                             modify total_fees_due               decimal(10,2) not null,
                             modify total_fees_paid            decimal(10,2) not null,
                             modify fees_due_today              decimal(10,2) not null,
                             modify composite_key              decimal(10,4) not null;
         })
      repository.adapter.execute(%Q{
         alter table cachers modify actual_outstanding_total decimal(10,2) not null, 
                             modify scheduled_outstanding_total decimal(10,2) not null,
                             modify actual_outstanding_principal decimal(10,2) not null,
                             modify scheduled_outstanding_principal decimal(10,2) not null,
                             modify scheduled_principal_due decimal(10,2) not null,
                             modify scheduled_interest_due  decimal(10,2) not null,
                             modify principal_due  decimal(10,2) not null,
                             modify interest_due decimal(10,2) not null,
                             modify principal_paid  decimal(10,2) not null,
                             modify interest_paid  decimal(10,2) not null,
                             modify total_interest_due  decimal(10,2) not null,
                             modify total_principal_due  decimal(10,2) not null,
                             modify total_principal_paid  decimal(10,2) not null,
                             modify total_interest_paid  decimal(10,2) not null,
                             modify advance_principal_paid decimal(10,2) not null,
                             modify advance_interest_paid  decimal(10,2) not null,
                             modify advance_principal_adjusted  decimal(10,2) not null,
                             modify advance_interest_adjusted   decimal(10,2) not null,
                             modify principal_in_default        decimal(10,2) not null,
                             modify interest_in_default         decimal(10,2) not null,
                             modify total_fees_due               decimal(10,2) not null,
                             modify total_fees_paid            decimal(10,2) not null,
                             modify fees_due_today              decimal(10,2) not null;
         })
    end
  end
end
    


