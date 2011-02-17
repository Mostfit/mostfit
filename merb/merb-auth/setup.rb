# This file is specifically setup for use with the merb-auth plugin.
# This file should be used to setup and configure your authentication stack.
# It is not required and may safely be deleted.
#
# To change the parameter names for the password or login field you may set either of these two options
#
# Merb::Plugins.config[:"merb-auth"][:login_param]    = :email 
# Merb::Plugins.config[:"merb-auth"][:password_param] = :my_password_field_name

begin
  # Sets the default class ofr authentication.  This is primarily used for 
  # Plugins and the default strategies
  Merb::Authentication.user_class = User 
  
  
  # Mixin the salted user mixin
  require 'merb-auth-more/mixins/salted_user'
  Merb::Authentication.user_class.class_eval{ include Merb::Authentication::Mixins::SaltedUser }
  
  Merb::Authentication.after_authentication do |user, request, params|
    if not user.active
      request.session.authentication.errors.add(:general, 'You are not an active user')
      nil
    elsif user.password_too_old
      request.session[:change_password] = true
      user
    else
      request.session[:last_seen] = Time.now
      user
    end
  end

  # Setup the session serialization
  class Merb::Authentication

    def fetch_user(session_user_id)
      if Mfi.first.session_expiry.is_a?(Numeric) and Mfi.first.session_expiry>30 and session.key?(:last_seen) and session[:last_seen].is_a?(Time) and Time.now - session[:last_seen] > Mfi.first.session_expiry
        session.abandon!
        raise SessionExpired
      else
        session[:last_seen] = Time.now
        Merb::Authentication.user_class.get(session_user_id)
      end
    end

    def store_user(user)
      user.nil? ? user : user.id
    end
  end
  
rescue
  Merb.logger.error <<-TEXT
  
    You need to setup some kind of user class with merb-auth.  
    Merb::Authentication.user_class = User
    
    If you want to fully customize your authentication you should use merb-core directly.  
    
    See merb/merb-auth/setup.rb and strategies.rb to customize your setup

    TEXT
end

