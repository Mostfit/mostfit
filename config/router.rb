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

  match('/data_entry/:action').to(:controller => 'data_entry').name(:data_entry)
  match('/graph_data').to(:controller => 'graph_data').name(:graph_data)
  match('/staff_member/:id/centers').to(:controller => 'staff_members', :action => 'show_centers').name(:show_staff_member_centers)
  # This is the default route for /:controller/:action/:id
#   default_routes
  
  # Change this for your home page to be available at /
  match('/').to(:controller => 'entrance', :action =>'root')
end
