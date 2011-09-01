class Cachers < Application

  def index
    debugger
    q = request.send(:query_params).blank? ? {:center_id => 0} : Marshal.load(Marshal.dump(request.send(:query_params)))
    q[:center_id] = 0 unless (params[:branch_id] or params[:stale])
    q[:stale] = q[:stale] == "true" ? true : [true, false] 
    @cachers = Cacher.all(q)
    display [@cachers], :layout => false
  end
  
end
