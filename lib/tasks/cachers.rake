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
  namespace :caches do
    desc "finds and adds caches for dates that are in loan history but not in the caches"
    task :do_missing do
      missing = BranchCache.missing
      total = missing.values.flatten.count
      i = 0
      missing.map do |k,v| 
        v.each do |d| 
          BranchCache.update(k,d) 
          i += 1
          puts "#{k}:#{d} (#{i}/#{total})"
        end
      end
    end
  end
end
