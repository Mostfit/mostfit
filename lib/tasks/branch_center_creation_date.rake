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
  desc "Fill creation dates for centers and branches, where there is none, equal to created_at"
  task :fill_creation_dates do
    Branch.all(:creation_date => nil).each{|branch|
      branch.creation_date = branch.created_at.to_date
      branch.save
    }
    Center.all(:creation_date => nil).each{|center|
      center.creation_date = center.created_at.to_date
      center.save
    }
  end
end
