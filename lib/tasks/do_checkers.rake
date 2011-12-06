require "rubygems"

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"
require "colored"
# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace :mostfit do
  namespace :data do
    desc "read all excel files in a directory and process them"
    task :check_all_checkers, :upload_id do |task, args|
      debugger
      select = {:ok => false}.merge( args[:upload_id] ? {:upload_id => args[:upload_id]} : {})
      cids = Checker.all(select).aggregate(:id)
      count = cids.count
      puts "Total to check: #{count}"
      t = Time.now
      cids.each_with_index do |cid, i|
        c = Checker.get(cid)
        c.check rescue nil
        if c.ok
          print ".".green
        else
          print ".".red
        end
        if i%50 == 0
          elapsed = (Time.now - t).to_f
          eta = (count - i) * (elapsed/i.to_f)
          puts "Did #{i}/#{count} in #{elapsed} secs. ETA: #{eta/60.0} mins"
        end
      end
    end
  end
end
