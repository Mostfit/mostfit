class Entrance < Application
  # the only unprotected action. not really needed (could do it straight from the router)
  # but in the future we probably need somthing more sophisticated here

  def root
    if session.authenticated?
      redirect url(:branches)
    else
      raise Unauthenticated
    end
  end
end