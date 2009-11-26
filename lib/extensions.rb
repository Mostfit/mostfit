module Misfit
  module Extensions

    module Browse
      def self.included(base)
        Merb.logger.info "Included Misfit::Extensions::Browse by #{base}"
        base.show_action(:centers_paying_today)
      end

      def before
        debugger
        if session.user.role == :staff_member
          @staff_member = session.user.staff_member
          @branches = Branch.all(:manager => @staff_member)
          @centers = Center.all(:manager => @staff_member)
          @template = 'browse/for_staff_member'
        end
      end
        
      
      def centers_paying_today
        @date = params[:date] ? Date.parse(params[:date]) : Date.today
        @centers = Center.all(:meeting_day => @date.weekday)
        render :template => 'dashboard/today'
      end
    end # Browse

    module User 
      #add hooks to before and after can_access? and can_manage? methods to override their behaviour
      # here we add hooks to see if the user can manage a particular instance of a model.
      def self.included(base)
        Merb.logger.info "Included Misfit::Extensions::User by #{base}"
        base.class_eval do
          alias :old_can_manage? :can_manage?
          alias :can_manage? :_can_manage?
          alias :old_can_access? :can_access?
          alias :can_access? :_can_access?

          #congratulations you have over-ridden the base methods
          # you can now pollute away
        end
      end

      def _can_manage?(model, id = nil)
        # this is the place to put all the ACL garbage so it doesn't pollute the core
        debugger
        return old_can_manage?(model) if (id.nil? or role != :staff_member)
        model = Kernel.const_get(model.to_s.camel_case)
        if model == Loan
          l = Loan.get(id)
          return l.client.center.manager == self.staff_member
        elsif model == Client
          c = Client.get(id)
          return c.center.manager == self.staff_member
        elsif model.relationships.has_key?(:manager)
          o = model.get(id)
          return o.manager == self.staff_member
        else
          return false
        end
      end
      
      def _can_access?(route,params = nil)
        # more garbage
        debugger
        return true if role == :admin
        return true if route[:controller] == "graph_data"
        controller = (route[:namespace] ? route[:namespace] + "/" : "" ) + route[:controller]
        model = route[:controller].singularize.to_sym
        action = route[:action]
        r = (access_rights[action.to_s.to_sym] or access_rights[:all])
        return false if r.nil?
        if role == :staff_member
          if route.has_key?(:id) and route[:id]
            return can_manage?(model, route[:id])
          end
          if controller == "payments"
            c = Center.get(route[:center_id])
            return (c.manager == staff_member and r.include?(:payments))
          end
          if controller == "data_entry/payments"
            if route[:action] == "by_center"
              c = Center.get(params[:center_id])
              return c ? c.manager == staff_member : false
            end
            if route[:action] == "by_staff_member"
              c = Center.get(params[:staff_member_id])
              return c ? c.manager == staff_member : false
            end
          end
        end
        r.include?(controller.to_sym) || r.include?(controller.split("/")[0].to_sym)
      end
    end #User

    def self.hook
      # includes the modules in their respective classes
      self.constants.each do |mod|
        object = Kernel.const_get(mod.to_s)
        object.class_eval do 
          Merb.logger.info("Hooking extensions for #{mod}")
          include module_eval("Misfit::Extensions::#{mod}")
        end
      end
    end
  end 
  

end
