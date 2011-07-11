if defined?(Merb::Plugins)

  $:.unshift File.dirname(__FILE__)

  dependency 'merb-slices', :immediate => true
  dependency 'cronedit', '0.3.0'
  dependency 'git', '1.2.5'
  Merb::Plugins.add_rakefiles "maintainer/merbtasks", "maintainer/slicetasks", "maintainer/spectasks"
  
  require 'slices/maintainer/lib/constants.rb'
  require 'slices/maintainer/lib/utils.rb'
  include Merb::Maintainer::Constants
  include Merb::Maintainer::Utils
  include Merb::Maintainer::Utils::Log
  include Merb::Maintainer::Utils::Database
  include Merb::Maintainer::Utils::Instance

  # Register the Slice for the current host application
  Merb::Slices::register(__FILE__)
  
  # Slice configuration - set this in a before_app_loads callback.
  # By default a Slice uses its own layout, so you can swicht to 
  # the main application layout or no layout at all if needed.
  # 
  # Configuration options:
  # :layout - the layout to use; defaults to :maintainer
  # :mirror - which path component types to use on copy operations; defaults to all
  Merb::Slices::config[:maintainer][:layout] ||= :maintainer
  
  # All Slice code is expected to be namespaced inside a module
  module Maintainer
    
    # Slice metadata
    self.description = "Maintainer is a chunky Merb slice!"
    self.version = "0.0.1"
    self.author = "Vicky Chijwani"
    
    # Stub classes loaded hook - runs before LoadClasses BootLoader
    # right after a slice's classes have been loaded internally.
    def self.loaded
    end
    
    # Initialization hook - runs before AfterAppLoads BootLoader
    def self.init
      Dir.mkdir_if_absent(slice_path("data"))
      Dir.mkdir_if_absent(slice_path("log"))
      Dir.mkdir_if_absent(app_path("tmp"))
    end
    
    # Activation hook - runs after AfterAppLoads BootLoader
    def self.activate
      DM_REPO.scope { Maintainer::DeploymentItem.create_from_last_commit if Maintainer::DeploymentItem.all.empty? }
    end
    
    # Deactivation hook - triggered by Merb::Slices.deactivate(Maintainer)
    def self.deactivate
    end
    
    # Setup routes inside the host application
    #
    # @param scope<Merb::Router::Behaviour>
    #  Routes will be added within this scope (namespace). In fact, any 
    #  router behaviour is a valid namespace, so you can attach
    #  routes at any level of your router setup.
    #
    # @note prefix your named routes with :maintainer_
    #   to avoid potential conflicts with global named routes.
    def self.setup_router(scope)
      # example of a named route
      # scope.match('/index(.:format)').to(:controller => 'main', :action => 'index').name(:index)
      scope.match('/maintain/:controller(/:action)').register

      # the slice is mounted at /maintainer - note that it comes before default_routes
      scope.match('/maintain').to(:controller => 'maintain', :action => 'index').name(:maintain)
      # enable slice-level default routes by default
      # scope.default_routes
    end
    
  end
  
  # Setup the slice layout for Maintainer
  #
  # Use Maintainer.push_path and Maintainer.push_app_path
  # to set paths to maintainer-level and app-level paths. Example:
  #
  # Maintainer.push_path(:application, Maintainer.root)
  # Maintainer.push_app_path(:application, Merb.root / 'slices' / 'maintainer')
  # ...
  #
  # Any component path that hasn't been set will default to Maintainer.root
  #
  # Or just call setup_default_structure! to setup a basic Merb MVC structure.
  Maintainer.setup_default_structure!
  
  # Add dependencies for other Maintainer classes below. Example:
  # dependency "maintainer/other"
  
end
