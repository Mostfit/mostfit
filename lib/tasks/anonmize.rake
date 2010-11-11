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
  namespace :data do
    desc "This rake task anonymizes client data"
    task :anonymizer do
      [Branch, Center, ClientGroup, LoanProduct, StaffMember, Client, Region, Area].each do |model|
        table=model.to_s.snake_case.pluralize
        model_string = model.to_s
        model.all.each_with_index do |obj, idx|        
          repository.adapter.execute("update #{table} set name='#{model_string} #{idx+1}' where id=#{obj.id}")
          repository.adapter.execute("update #{table} set spouse_name='#{model_string} #{idx+1}' where id=#{obj.id}") if model==Client
        end        
      end
      #User.all(:login.not => "admin").destroy!
      
    end
  end
end
