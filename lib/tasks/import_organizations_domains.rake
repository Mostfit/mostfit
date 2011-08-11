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
      file = File.read(filename)
      if file
        YAML::load(File.read(filename)).each do |record|
          org = Organization.create(:org_guid => record["org_guid"], 
                                    :name => record["name"],
                                    :domains => record["domains"])
        end
      else
        puts "The organizations.yml file is not in its proper location or does not have the correct name. Please put the file in #{Merb.root}/doc/input and rename it as organizations.yml"
      end
    end

    desc "This rake task imports organization and domains data from a xml file"
    task :format_xml do
      filename = File.join(Merb.root, 'doc', 'input', 'organizations.xml')
      file = File.read(filename)
      unless file
        # YAML::load(File.read(filename)).each do |record|
        #   Organization.create(:org_guid => record["guid"], 
        #                       :name => record["name"],
        #                       :domains => record["domains"])
        # end
      else
        puts "The organizations.xml file is not in its proper location or does not have the correct name. Please put the file in #{Merb.root}/doc/input and rename it as organizations.xml"
      end
    end
  end
end
