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
    desc "read all excel files in a directory and process them"
    task :process_upload_directory do
      file_list = Dir.glob(File.join(Merb.root,"uploads","*xls"))
      puts "found #{file_list}.count files"
      uploads = []
      file_list.each do |f|
        puts "copying #{f}"
        u = Upload.make(:file => {:filename => f.split("/")[-1], :tempfile => File.new(f,"r")}, :user => User.first)
        uploads.push u
      end
      uploads.each do |u|
        # u.cont
      end
    end
  end
end
