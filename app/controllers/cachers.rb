class Cachers < Application

  def index
    q = request.send(:query_params).blank? ? {:center_id => 0} : request.send(:query_params)
    @cachers = Cacher.all(q)
    display [@cachers], :layout => false
  end
  
end
