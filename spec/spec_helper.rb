require "rubygems"

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

  config.before(:all) do
    DataMapper.auto_migrate! if Merb.orm == :datamapper
  end
  
end

def load_fixtures(*files)
  DataMapper.auto_migrate! if Merb.orm == :datamapper
  files.each do |name|
    klass = Kernel::const_get(name.to_s.singularize.camel_case)
    yml_file =  "spec/fixtures/#{name}.yml"
    entries = YAML::load_file(Merb.root / yml_file)
    entries.each do |name, entry|
      k = klass::new(entry)
      k.history_disabled = true if k.class == Loan  # do not update the hisotry for loans
      k.client_type = ClientType.first if k.class==Client
      unless k.save        
        puts "Validation errors saving a #{klass} (##{k.id}):"
        p k.errors
      end
    end
  end
end

