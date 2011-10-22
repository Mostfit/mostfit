class Exceptions < Merb::Controller
  provides :xml, :yaml, :js  
  # handle NotFound exceptions (404)
  def not_found
    if request.xhr?
      return("Sorry! Not found.")
    elsif request.env['HTTP_REFERER']
      redirect request.env['HTTP_REFERER'], :message => { :error => 'Sorry, page not found' }
    else
#      only_provides :xml
      render :status => 404
    end
  end

  # handle NotAcceptable exceptions (400)
  def bad_request
    if request.xhr?
      return("Sorry! Missing parameters. Please fill the form correctly")
    elsif request.env['HTTP_REFERER']
      redirect request.env['HTTP_REFERER'], :message => { :error => 'Sorry! Missing parameters. Please fill the form correctly' }
    else
      render :format => :html, :layout => layout?, :status => 400
    end
  end

  # handle NotAcceptable exceptions (406)
  def not_complete
    if request.xhr?
      return("Sorry! Not found.")
    elsif request.env['HTTP_REFERER']
      redirect request.env['HTTP_REFERER'], :message => { :error => 'Sorry, not acceptable' }
    else
      render :format => :html, :layout => layout?, :status => 406
    end
  end

  def not_privileged
    if request.xhr?
      return("Sorry! Not allowed to perform this action.")
    elsif request.env['HTTP_REFERER'] 
      redirect request.env['HTTP_REFERER'], :message => { :error => 'Sorry, not enough privileges to do this' }
    else
      render :status => 403
    end
  end

  def not_supported_pattern
    render :status => 403
  end


  def not_authorized
    return "Not privileged" if request.xhr?
    render :status => 403
  end

  def session_expired
    if request.xhr?
      return("Sorry! Your session has expired.")
    elsif request.env['HTTP_REFERER'] 
      redirect request.env['HTTP_REFERER'], :message => { :error => 'Sorry, your session has expired' }
    else
      render
    end
  end

  def not_changeable
    if request.xhr?
      return("Sorry! Not allowed to change verified data.")
    elsif request.env['HTTP_REFERER'] 
      redirect request.env['HTTP_REFERER'], :message => { :error => 'Sorry, Not allowed to change verified data.' }
    else
      render
    end    
  end

 
  #get list of errors handle 
  def index
    display @template
  end
end

class NotPrivileged <  Merb::ControllerExceptions::Unauthorized; end
class NotChangeable <  Merb::ControllerExceptions::Unauthorized; end
class SessionExpired < Merb::ControllerExceptions::Unauthorized; end
class NotSupportedPattern < Merb::ControllerExceptions::Unauthorized; end
