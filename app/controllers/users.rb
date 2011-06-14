class Users < Application
  before :ensure_admin, :only => [:edit, :new, :create, :update, :delete, :destroy, :amind_change_password]

  def show(id)
    @user = User.get(id)
    raise NotFound unless @user
    @trails = AuditTrail.all(:auditable_id => @user.id, :auditable_type => "User", :order => [:created_at.desc])
    @obj = @user
    display @user
  end

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
    @user_password = @user
    raise NotFound unless @user
    display @user
  end

  def create(user)
    params[:user][:staff_member] = StaffMember.get(params[:user][:staff_member]) if params[:user][:staff_member]
    params[:user][:funder]       = Funder.get(params[:user][:funder]) if params[:user][:funder]
    params[:user][:password_changed_at] = Time.now
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

  def admin_change_password    
    user = params[:user]
    @user = User.get(params[:user_id])
    raise NotFound unless @user

    @status = false
    if session.user.role == :admin and request.method==:put and user.key?(:password) and 
        user.key?(:password_confirmation) and not user[:password].blank? and not user[:password_confirmation].blank?
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
    end

    if @status
      redirect(resource(:users), :message => {:notice => "Password changed successfully"})
    else
      message[:error] = "Password could not be changed"
      display @user, :edit
    end
  end
end # Users
