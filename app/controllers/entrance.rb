class Entrance < Merb::Controller  # not inherit from Application as that thing is authenticated

  def index
    render
  end

  def about
    render
  end

  def root
#    redirect url(:entrance)  # no switch, nicer for the demo
    if session.authenticated?
      if session.user.role==:data_entry
        redirect url(:data_entry)
      else 
        redirect url(:browse)  # this should be the cockpit page in later versions
      end
    else
      redirect url(:entrance)
    end
  end


end
