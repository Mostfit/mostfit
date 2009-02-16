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


  # This is the default route for /:controller/:action/:id
#   default_routes
  
  match('/entrance').to(:controller => 'entrance').name(:entrance)
  match('/').to(:controller => 'entrance', :action =>'root')
end
