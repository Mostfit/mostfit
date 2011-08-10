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
  namespace :import_organizations do
    desc "This rake task imports organization and domains data from an yml file"
    task :format_yml do
      filename = File.join(Merb.root, 'doc', 'input', 'organizations.yml')
      # File.open(filename, 'r') do |file|
      debugger
      YAML::load(File.read(filename)).each do |record|
	debugger
        Organization.create(:guid => record["guid"], 
                            :name => record["name"],
                            :domains => record["domains"])
      end
      #end
    end

    desc "This rake task imports organization and domains data from a xml file"
    task :format_xml do
            
    end
  end
end
