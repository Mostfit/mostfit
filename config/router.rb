Merb.logger.info("Compiling routes...")
Merb::Router.prepare do
  resources :users
  resources :staff_members
  # RESTful routes
  resources :branches  do
    resources :centers  do
      resources :clients do
        resources :loans  do
          resources :payments
        end
      end
    end
  end
  
  # Adds the required routes for merb-auth using the password slice
  slice(:merb_auth_slice_password, :name_prefix => nil, :path_prefix => "")

  match('/data_entry').to(:namespace => 'data_entry', :controller => 'index').name(:data_entry)
  namespace :data_entry, :name_prefix => 'enter' do
    match('/clients(/:action)').to(:controller => 'clients').name(:clients)
    match('/loans(/:action)').to(:controller => 'loans').name(:loans)
    match('/payments(/:action)').to(:controller => 'payments').name(:payments)
    match('/attendancy(/:action)').to(:controller => 'attendancy').name(:attendancy)
  end

  match('/graph_data/:action(/:id)').to(:controller => 'graph_data').name(:graph_data)
  match('/staff_member/:id/centers').to(:controller => 'staff_members', :action => 'show_centers').name(:show_staff_member_centers)
  match('/branches/:id/today').to(:controller => 'branches', :action => 'today').name(:branch_today)
  match('/entrance').to(:controller => 'entrance').name(:entrance)


  # This is the default route for /:controller/:action/:id
#   default_routes

  # this uses the redirect_to_show methods on the controllers to redirect some models to their appropriate urls
  match('/:controller/:id').to(:action => 'redirect_to_show').name(:quick_link)

  match('/').to(:controller => 'entrance', :action =>'root')
end
