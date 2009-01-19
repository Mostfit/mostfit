# Go to http://wiki.merbivore.com/pages/init-rb
 
require 'config/dependencies.rb'
 
use_orm :datamapper
use_test :rspec
use_template_engine :haml
 
Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:session_store] = 'cookie'  # can also be 'memory', 'memcache', 'container', 'datamapper
  
  # cookie session store configuration
  c[:session_secret_key]  = '573a2e64628a0656a8149f6f6b802d11bfc74123'  # required for cookie session store
  c[:session_id_key] = '_mostfit_session_id' # cookie session id key, defaults to "_session_id"
end
 
Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
  begin
    if User.all.empty?
      u = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password')
      if u.save
        Merb.logger.info("The initial user 'admin' was created (password is set to 'password')...")
      else
        Merb.logger.info("Couldn't create the 'admin' user...")
      end
    end
  rescue
    Merb.logger.info("Couldn't create the 'admin' user, possibly unable to access the database.")
  end

end
