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
    desc "convert to new-layout branch"
    task :to_new_layout do
      repository.adapter.execute("truncate table loan_history;")
      Rake::Task['db:autoupgrade'].invoke
      Rake::Task['mostfit:db:prepare'].invoke
      Rake::Task['mostfit:conversion:update_loan_cache'].invoke
      Rake::Task['mostfit:data:create_history'].invoke
    end
  end
end
