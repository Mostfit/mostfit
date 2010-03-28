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
  desc "populate the database using the csv's"
  task :sync_audit_trails do
    [Branch, Center, Client, Loan, Payment].each{|klass|
      klass.all.each{|obj|
        changes = [obj.attributes.select{|k, v| v and not v.blank? and not v==0}.to_hash]
        changes.first[:discriminator] = changes.first[:discriminator].to_s if klass==Loan
        if not AuditTrail.first(:auditable_id => obj.id, :auditable_type => klass.to_s, :action => :create)          
          AuditTrail.create(:auditable_id => obj.id, :auditable_type => klass.to_s, :action => :create, :changes => changes, :type => :log, 
                            :user => (obj.respond_to?(:created_by) and obj.created_by) ? obj.created_by : User.first)
        end
      }
    }
  end
end
