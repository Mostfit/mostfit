module Misfit
  module Extensions

    module Browse
      def self.included(base)
        Merb.logger.info "Included Misfit::Extensions::Browse by #{base}"
        base.show_action(:centers_paying_today)
      end
      
      def centers_paying_today
        @date = params[:date] ? Date.parse(params[:date]) : Date.today
        @centers = Center.all(:meeting_day => @date.weekday)
        render :template => 'dashboard/today'
      end
    end # Browse

    def self.hook
      # includes the modules in their respective classes

      self.constants.each do |mod|
        object = Kernel.const_get(mod.to_s)
        object.class_eval do 
          include (Kernel.const_get("Misfit::Extensions::#{mod}"))
        end
      end
    end
  end 
  

end
