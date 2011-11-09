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

namespace :mostfit do
  namespace :conversion do
    desc "This rake task adds some cached values to loans"
    task :update_loan_cache do
      puts "marking centers..."
      repository.adapter.execute(%Q{
          UPDATE loans 
          SET c_center_id = (SELECT cn.id from centers cn, clients cs
             WHERE loans.client_id = cs.id AND cs.center_id = cn.id)})
      puts "marking branches..."
      repository.adapter.execute(%Q{
          UPDATE loans 
          SET c_branch_id = 
             (SELECT b.id from centers cn, clients cs, branches b
             WHERE loans.client_id = cs.id AND cs.center_id = cn.id AND cn.branch_id = b.id)})
      puts "marking client groups..."
      repository.adapter.execute(%Q{
          UPDATE loans 
          SET c_client_group_id =
          (SELECT c.client_group_id from clients c 
             WHERE loans.client_id = c.id)})
      
    end
  end
end
