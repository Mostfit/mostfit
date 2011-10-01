# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you

#This rake tase generating mostfit.pot file in config/locales
#Adding all text in .pot file for supporting diffrent language
#TODO: [for fix] If mostfit.pot file alrady available then remove that file before run this rake task
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')
namespace :mostfit do
  desc "Update pot/po files."
  task :create_po do
    require 'gettext/tools'
    require 'haml_parser'
    begin
    MY_APP_TEXT_DOMAIN = "mostfit" 
    MY_APP_VERSION     = "Mostfit 1.1.0"
     GetText.update_pofiles(MY_APP_TEXT_DOMAIN, Dir.glob("{app/views}/**/*.{html.haml}"),
                         MY_APP_VERSION, :po_root => 'config/locales')
    rescue Exception => e
      puts e
    end
  end
end
