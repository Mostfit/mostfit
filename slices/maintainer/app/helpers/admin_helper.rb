module Merb::Maintainer::AdminHelper
  
  def create_user
    if User.all(:login => params[:login]).length > 0
      ret = "user_exists"
    else
      if params.has_key? :password and params.has_key? :password_confirmation and params[:password] == params[:password_confirmation]
        u = User.new(:login => params[:login], :role => :maintainer)
        u.password = params[:password]
        u.password_confirmation = params[:password_confirmation]
        ret = u.save ? "true" : "false"
      else
        ret = "different_passwords"
      end
    end
    if ret == "true"
      log(
        :action => 'added_maintainer',
        :ip     => request.remote_ip,
        :name   => params[:login]
      )
    end
    return ret
  end

  def enable_user
    @maintainers.all(:login => params[:user]).update(:active => true)
    log(
      :action => 'enabled_maintainer',
      :ip     => request.remote_ip,
      :name   => params[:user]
    )
    return "true"
  end

  def disable_user
    if operation_allowed?
      @maintainers.all(:login => params[:user]).update(:active => false)
      ret = "true"
    else
      ret = "atleast_one_maintainer_required"
    end
    if ret == "true"
      log(
        :action => 'disabled_maintainer',
        :ip     => request.remote_ip,
        :name   => params[:user]
      )
    end
    return ret
  end

  def delete_user
    if operation_allowed?
      @maintainers.all(:login => params[:user]).destroy
      ret = "true"
    else
      ret = "atleast_one_maintainer_required"
    end
    if ret == "true"
      log(
        :action => 'deleted_maintainer',
        :ip     => request.remote_ip,
        :name   => params[:user]
      )
    end
    return ret
  end

  # Do not allow a change if passwords are different
  # or if the new password is same as the old one
  def password_update
    user = session.user
    status = false
    ret = nil
    if params.has_key? :password and params.has_key? :password_confirmation and params[:password] == params[:password_confirmation]
      user.transaction do |t|
        old_crypt = user.crypted_password
        user.password = params[:password]
        user.password_confirmation = params[:password]
        user.password_changed_at = DateTime.now
        status = user.save
        ret = "true"
        if not status
          t.rollback
          ret = "error"
        end
        if user.crypted_password == old_crypt
          status = false
          t.rollback
          ret = "same_password"
        end
      end
    else
      ret = "different_passwords"
    end
    session.delete(:change_password) if status and session.has_key? :change_password
    if ret == "true"
      log(
        :action => 'changed_password',
        :ip     => request.remote_ip
      )
    end
    return ret
  end

end
