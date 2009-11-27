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
    @user = User.new(user)
    if @user.save
      redirect resource(:users), :message => {:notice => "Successfully created user '#{@user.login}'"}
    else
      message[:error] = "Could not create the user."
      render :new
    end
  end

  def update(id, user)
    debugger
    @user = User.get(id)
    params[:user][:staff_member] = StaffMember.get(params[:user][:staff_member]) if params[:user][:staff_member]
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

  private
  def ensure_is_admin
    raise Unauthenticted unless session.user.id == 1
  end
end # Users
