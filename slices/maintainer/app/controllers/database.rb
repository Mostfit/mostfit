class Maintainer::Database < Maintainer::Application

  def index
    render :layout => false
  end

  def take_snapshot
    snapshot_path = database_backup
    log({
      :action => 'took_snapshot',
      :ip     => request.remote_ip,
      :name   => File.basename(snapshot_path)
    })
    (request.xhr?) ? (return "true") : redirect("/maintain#database")
  end

  def download_dump(file)
    log({
      :action => 'downloaded_dump',
      :ip     => request.remote_ip,
      :name   => file
    })
    path = File.join(DUMP_FOLDER, file)
    return send_data(File.open(path), :filename => file, :type => "bzip2") if file and File.exists?(path)
  end

  def delete(file)
    path = File.join(DUMP_FOLDER,file)
    File.delete(path) if file and File.exists?(path)
    log({
      :action => 'deleted_dump',
      :ip     => request.remote_ip,
      :name   => file
    })
    (request.xhr?) ? (return "true") : redirect("/maintain#database")
  end

end
