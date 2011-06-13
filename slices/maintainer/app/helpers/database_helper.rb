module Merb
  module Maintainer
    module DatabaseHelper
      
      DUMP_FOLDER = "db/daily"
      DB_FOLDER = "db"

      def get_snapshots
        snapshots = []
        if File.exists?(DUMP_FOLDER) and File.directory?(DUMP_FOLDER)
          Dir.chdir(DUMP_FOLDER)
          Dir.glob("*").sort {
            |a,b| File.mtime(b) <=> File.mtime(a)
          }.each do |filename|
            unless /^\.+$/ =~ filename
              f = File.open(File.join(Merb.root,DUMP_FOLDER,filename))
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
  end
end
