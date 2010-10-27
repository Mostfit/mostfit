Merb.logger.info("Compiling access control...")
Merb::Acl::Rule.prepare do |rule|
  rule.allow 'admin'

  rule.allow 'mis_manager', :for => {:controllers =>  all_controllers - [:users, :admin]}

  rule.allow 'data_entry', :for => {:controllers =>  all_controllers - [:users, :admin], :methods => [:get]}
  rule.allow 'data_entry', :for => {:controllers =>  [:client, :loan, :payment]}

  rule.allow('staff_members',
             :for => {
               :controllers => [:browse, :centers, :payments, :clients, :"data_entry/payments", :"data_entry/clients", :"data_entry/loans", :"data_entry/index"]
             }, :before => :is_owner)
  
  rule.allow 'read_only', :for => {:controller => all_controllers, :method => [:get]}
end
