class Maintainer::Status < Maintainer::Application

  def index
    @mysql_password = YAML::load_file("#{Merb.root}/config/database.yml")["production"]["password"]
    @mysql_user = YAML::load_file("#{Merb.root}/config/database.yml")["production"]["username"]
    @db = YAML::load_file("#{Merb.root}/config/database.yml")["production"]["database"]
    render :layout => false
  end

end
