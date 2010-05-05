class Exceptions < Merb::Controller
  
  # handle NotFound exceptions (404)
  def not_found
    render :format => :html
  end

  # handle NotAcceptable exceptions (406)
  def not_acceptable
    render :format => :html
  end

  def not_privileged
    if request.xhr?
      return("Sorry! Not allowed to perform this action.")
    elsif request.env['HTTP_REFERER'] 
      redirect request.env['HTTP_REFERER'], :message => { :error => 'Sorry, not enough privileges to do this' }
    else
      render
    end
  end

  def not_authorized
    return "Not privileged" if request.xhr?
    render
  end

end

class NotPrivileged <  Merb::ControllerExceptions::Unauthorized; end

