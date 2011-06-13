class Maintainer::Database < Maintainer::Application
  
  DUMP_FOLDER = Merb::Maintainer::DatabaseHelper::DUMP_FOLDER
  DB_FOLDER = Merb::Maintainer::DatabaseHelper::DB_FOLDER

  def index
    render :layout => false
  end

  def take_snapshot
    db_config = YAML.load(File.read('config/database.yml'))
    env = Merb.env
    username = db_config[env]["username"]
    password = db_config[env]["password"]
    database = "intaglio" #db_config[env]["database"]
    host = db_config[env]["host"]
    pwd = Merb.root
    today = `date +%H:%M:%S.%Y-%m-%d`.chomp
    snapshot_path = File.join(pwd,DUMP_FOLDER,"#{database.sub(/^mostfit_/,'')}.#{today}.sql")

    if File.exists?(snapshot_path+".bz2")
      return "false"
    else
      db_folder_path = File.join(pwd,DB_FOLDER)
      dump_folder_path = File.join(pwd,DUMP_FOLDER)
      
      Dir.mkdir(db_folder_path) unless File.exists?(db_folder_path) and File.directory?(db_folder_path)
      Dir.mkdir(dump_folder_path) unless File.exists?(dump_folder_path) and File.directory?(dump_folder_path)
      
      `mysqldump -u #{username} -p#{password} #{database} > #{snapshot_path}; bzip2 #{snapshot_path}`
      
      log({
        :action => 'took_snapshot',
        :ip     => request.remote_ip,
        :name   => File.basename(snapshot_path)
      })
      return "true"
    end
  end

  def download_dump(file)
    log({
      :action => 'downloaded_dump',
      :ip     => request.remote_ip,
      :name   => file
    })
    send_data(File.open(File.join(Merb.root, DUMP_FOLDER, file)), :filename => file, :type => "bzip2") if file and File.exists?(File.join(Merb.root, DUMP_FOLDER, file))
  end

  def log(data)
    h = DataMapper.repository(:maintainer) {
      Maintainer::HistoryItem.create(
        :user_name   => session.user.login,
        :ip          => data[:ip],
        :time        => Time.now,
        :action      => data[:action],
        :data        => data[:name]
      )
    }
  end

end
