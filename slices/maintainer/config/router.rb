# This file is here so slice can be testing as a stand alone application.

Merb::Router.prepare do
  slice(Maintainer, :path_prefix => '/maintain') do
    # match('/deployment').to(:controller => 'maintain', :action => 'deployment').name(:deployment)
    # match('/database').to(:controller => 'maintain', :action => 'database').name(:database)
    # match('/cron').to(:controller => 'maintain', :action => 'cron').name(:cron)
    # match('/security').to(:controller => 'maintain', :action => 'security').name(:security)
    # match('/reporting').to(:controller => 'maintain', :action => 'reporting').name(:reporting)
  end
end
