class MerbAuthSlicePassword::Sessions < MerbAuthSlicePassword::Application
  
  before :_maintain_auth_session_before, :exclude => [:destroy]  # Need to hang onto the redirection during the session.abandon!
  before :_abandon_session,     :only => [:update, :destroy]
  before  :_maintain_auth_session_after,  :exclude => [:destroy]  # Need to hang onto the redirection during the session.abandon!
  before :ensure_authenticated, :only => [:update]

  # redirect from an after filter for max flexibility
  # We can then put it into a slice and ppl can easily 
  # customize the action
  after :redirect_after_login,  :only => :update, :if => lambda{ !(300..399).include?(status) }
  after :redirect_after_logout, :only => :destroy
  
  def update
    "Add an after filter to do stuff after login"
    # this is where the default scope hooks go
  end

  def destroy
    "Add an after filter to do stuff after logout"
  end
  
  
  private   
  # @overwritable
  def redirect_after_login
    message[:notice] = "Authenticated Successfully"
    case session.user.role
    when :data_entry
      redirect url(:data_entry)
    when :staff_member
      redirect(url(:browse))
    else
      redirect_back_or(url(:browse), :message => message, :ignore => [slice_url(:login), slice_url(:logout)])
    end
  end

  # @overwritable
  def redirect_after_logout
    message[:notice] = "Logged Out"
    redirect "/", :message => message
  end  

  # @private
  def _maintain_auth_session_before
    @_maintain_auth_session = {}
    Merb::Authentication.maintain_session_keys.each do |k|
      @_maintain_auth_session[k] = session[k]
    end
  end
  
  # @private
  def _maintain_auth_session_after
    @_maintain_auth_session.each do |k,v|
      session[k] = v
    end
  end
  
  # @private
  def _abandon_session
    session.abandon!
  end
end
