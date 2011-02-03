class Users < Application

  def index
    @users = User.all
    display @users
  end

  def new
    only_provides :html
    @user = User.new
    display @user
  end

  def edit(id)
    only_provides :html
    @user = User.get(id)
    raise NotFound unless @user
    display @user
  end

  def create(user)
    params[:user][:staff_member] = StaffMember.get(params[:user][:staff_member]) if params[:user][:staff_member]
    params[:user][:funder]       = Funder.get(params[:user][:funder]) if params[:user][:funder]
    @user = User.new(user)
    if @user.save
      redirect resource(:users), :message => {:notice => "Successfully created user '#{@user.login}'"}
    else
      message[:error] = "Could not create the user."
      render :new
    end
  end

  def update(id, user)
    @user = User.get(id)
    params[:user][:staff_member] = StaffMember.get(params[:user][:staff_member]) if params[:user][:staff_member]
    params[:user][:funder]       = Funder.get(params[:user][:funder]) if params[:user][:funder]
    raise NotFound unless @user
    if @user.update_attributes(user)
      redirect resource(:users), :message => {:notice => "User '#{@user.login}' has been modified"}
    else
      display @user, :edit
    end
  end

  def delete(id)
    only_provides :html
    @user = User.get(id)
    raise NotFound unless @user
    display @user
  end

  def destroy(id)
    @user = User.get(id)
    raise NotFound unless @user
    if @user.destroy
      redirect resource(:users), :message => {:notice => "User '#{@user.login}' has been deleted"}
    else
      redirect resource(:users), :message => {:error => "Could not delete user '#{@user.login}'."}
    end
  end

  # Allow users to change their passwords
  # Do not allow a change if passwords are different
  # or if the new password is same as the old one
  def change_password    
    user = params[:user]
    @user = session.user
    @status = false
    if request.method==:put and user.key?(:password) and user.key?(:password_confirmation)
      @user.transaction do |t|
        old_crypt = @user.crypted_password
        @user.password = user[:password]
        @user.password_confirmation = user[:password]
        @user.password_changed_at   = DateTime.now
        @status = @user.save
        t.rollback if not status
        if (@user.crypted_password == old_crypt)
          t.rollback
          @status = false
          @user.errors.add(:password, "Same as old password")
        end
      end

      if @status
        session.delete(:change_password) if session.key?(:change_password)
        redirect("/browse", :message => {:notice => "Password changed successfully"})
      end
    end
    render
  end
  
  private
  def ensure_is_admin
    raise Unauthenticted unless session.user.id == 1
  end
end # Users
