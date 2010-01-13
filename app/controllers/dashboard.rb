class Dashboard < Application

  def index
    @graph1 = ofc2(430, 200, url(:graph_data, :action => 'dashboard', :id => 'client_growth',  :scope_unit => 'months', :scope_size => 3))
    @graph2 = ofc2(430, 200, url(:graph_data, :action => 'dashboard', :id => 'branch_pie',  :scope_unit => 'months', :scope_size => 3))
    @graph3 = ofc2(430, 200, url(:graph_data, :action => 'dashboard', :id => 'client_cumulative',  :scope_unit => 'months', :scope_size => 3))
    @graph4 = ofc2(430, 200, url(:graph_data, :action => 'total', :scope_unit => 'months', :scope_size => 3))
    render
  end

  def today
    @date = params[:date].blank? ? Date.today : Date.parse(params[:date])
    render
  end
  
end
