require "rubygems"
require "erb"
require File.join(File.dirname(__FILE__), 'spec_helper_html.rb')
# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"
require "spec" # Satisfies Autotest and anyone else not using the Rake tasks

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:testing => true, :adapter => 'runner', :environment => ENV['MERB_ENV'] || 'test')
Spec::Runner.configure do |config|
#  config.include(Merb::Test::ViewHelper)
  config.include(Merb::Test::RouteHelper)
  config.include(Merb::Test::ControllerHelper)
  config.include(Spec::Matchers)
  
  config.before(:all) do
    if Merb.orm == :datamapper
      DataMapper.auto_migrate!
      (repository.adapter.query("show tables") - ["payments", "journals", "postings"]).each{|t| repository.adapter.execute("alter table #{t} ENGINE=MYISAM")}
    end

    mfi = Mfi.first
    mfi.accounting_enabled = false
    mfi.dirty_queue_enabled = false
    mfi.in_operation_since = Date.new(2000, 01, 01)
    mfi.save
  end
end


class MockLog
  def info(data)
  end

  def error(data)
  end
end
