module Merb::Maintainer::DatabaseHelper

  DUMP_FOLDER = Merb::Maintainer::Constants::DUMP_FOLDER
  
  def get_snapshots
    snapshots = []
    if File.directory?(DUMP_FOLDER)
      Dir.chdir(DUMP_FOLDER)
      Dir.glob("*").sort {
        |a,b| File.mtime(b) <=> File.mtime(a)
      }.each do |filename|
        unless /^\.+$/ =~ filename
          f = File.open(File.join(DUMP_FOLDER,filename))
          snapshots << {
            :name => filename,
            :date => f.mtime,
            :size => File.size(f.path)
          }
        end
      end
      Dir.chdir(Merb.root)
    end
    snapshots
  end

end
