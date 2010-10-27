module Merb
  module Acl
    def crud_rights
      Misfit::Config.crud_rights[role]
    end
    
    def access_rights
      Misfit::Config.access_rights[role]
    end

    def self.deploy
      load(File.join(Merb.root, "config", "acl.rb"))
    end
    
    class Rule
      @@rules = {}
      REJECT_REGEX = /^(Merb|merb)::*/

      def initialize
        all_controllers.each{|controller|
          @@rules[controller] = {}
          all_actions(controller).each{|action|
            @@rules[controller][action] = {}
          }
        }        
      end
      
      def all_controllers
        Application.subclasses_list.reject{|x| REJECT_REGEX.match(x)}.map{|x|
          x.snake_case.to_sym
        }
      end

      def all_actions(controller)
        get_controller(controller).callable_actions.collect{|x| x[0].to_sym}
      end
      
      def all_methods
        http_methods
      end

      def allow(role, hash = {})
        set_rules(role, hash = {})
      end

      def deny(role, hash = {})
        set_rules(role, hash = {}, false)
      end
      
      def self.prepare(&blk)
        self.new.instance_eval(&blk)
      end
      
      def self.rules
        @@rules
      end
      
      private
      def http_methods
        [:get, :put, :post, :delete]
      end
      
      def get_controller(controller)
        controller.to_s.split("::").collect{|x| x.split(/_/).collect{|seg| seg.capitalize}.join}.inject(Object){|parent, child|
          parent.const_get(child)
        }
      end

      def set_rule(controller, action, method, role, allow=true)
        @@rules[controller][action][method]||=[]
        if allow and not @@rules[controller][action][method].include?(role)
          @@rules[controller][action][method].push(role)
        elsif @@rules[controller][action][method].include?(role)
          @@rules[controller][action][method].delete(role)
        end
      end

      def set_rules(role, hash = {}, allow=true)
        role =  role.to_sym
        controllers = []
        controllers = (hash.key?(:for) and hash.key?(:controllers)) ? hash[:controllers] : all_controllers
        controllers.each{|controller|
          actions     = (hash.key?(:for) and hash.key?(:actions))   ? hash[:actions]     : all_actions(controller)  
          actions.each{|action|
            http_methods.each{|method|
              set_rule(controller, action, method, role, allow)
            }            
            hash[:methods].each{|method|
              set_rule(controller, action, method, role, allow)
            } if hash.key?(:methods)
          }
        }
      end
    end
    
    def can_access?(route, params = nil)
      return true if role == :admin
      return true if route[:controller] == "graph_data"
      controller = (route[:namespace] ? route[:namespace] + "/" : "" ) + route[:controller]
      model = route[:controller].singularize.to_sym
      action = route[:action]
      if route.has_key?(:id)
        return can_manage?(model, route[:id])
      end
      r = (access_rights[action.to_s.to_sym] or access_rights[:all])
      return false if r.nil?
      r.include?(controller.to_sym) or r.include?(controller.split("/")[0].to_sym)
    end
    
    def can_manage?(model, id = nil)
      return true if role == :admin
      return crud_rights.values.inject([]){|a,b| a + b}.uniq.include?(model.to_s.snake_case.to_sym)
    end
    
    def method_missing(name, params)
      if x = /can_\w+\?/.match(name.to_s)
        return true if role == :admin
        function = x[0].split("_")[1].gsub("?","").to_sym # wtf happened to $1?!?!?
        puts function
        raise NoMethodError if not ([:edit, :update, :create, :new, :delete, :destroy].include?(function))
        model = params
        r = (crud_rights[function] or crud_rights[:all])
        return false if r.nil?
      r.include?(model)
      else
        raise NoMethodError
      end
    end
    
    module User
      #add hooks to before and after can_access? and can_manage? methods to override their behaviour
      # here we add hooks to see if the user can manage a particular instance of a model.
      def self.included(base)
        Merb.logger.info "Included Misfit::Extensions::User by #{base}"
        base.class_eval do
          alias :old_can_access? :can_access?
          alias :can_access? :_can_access?
          
          #congratulations you have over-ridden the base methods
          # you can now pollute away
        end
      end
      
      def can_approve?(loan)
        if role == :staff_member
          return (loan.client.center.manager == staff_member or loan.client.center.branch.manager == staff_member)
        end
        return false if role == :read_only
        return true
      end
      
      def additional_checks
        id = @route[:id]
        model = Kernel.const_get(@model.to_s.capitalize)
        if model == Loan
          l = Loan.get(id)
          return ((l.client.center.manager == self.staff_member) or (l.client.center.branch.manager == self.staff_member))
        elsif model == Client
          c = Client.get(id)
          return ((c.center.manager == self.staff_member) or (c.center.branch.manager == self.staff_member))
        elsif model == Center
          center = Center.get(id)
          if @action != "show"
            return center.branch.manager == self.staff_member
          else
            return center.manager == self.staff_member
          end
        elsif model.relationships.include?(:manager)
          o = model.get(id)
          return true if o.manager == self.staff_member
        else
          return false
        end
      end
      
      def _can_access?(route,params = nil)
        # more garbage
        return true if role == :admin
        return true if route[:controller] == "graph_data"        
        @route = route
        @controller = (route[:namespace] ? route[:namespace] + "/" : "" ) + route[:controller]
        @model = route[:controller].singularize.to_sym
        @action = route[:action]
        return true if @action == "redirect_to_show"
        r = (access_rights[@action.to_s.to_sym] or access_rights[:all])
        return false if @action == "approve" and role == :data_entry
        return false if r.nil?
        if role == :staff_member
          if @route.has_key?(:id) and @route[:id]
            return additional_checks
          end
          if @controller == "payments"
            c = Center.get(@route[:center_id])
            return ((c.manager == staff_member or c.branch.manager == staff_member) and r.include?(:payments))
          end
          if @controller == "data_entry/payments"
            if route[:action] == "by_center"
              c = Center.get(params[:center_id])
              return c ? (c.manager == staff_member or c.branch.manager == staff_member) : false
            end
            if @route[:action] == "by_staff_member"
              c = Center.get(params[:staff_member_id])
              return c ? (c.manager == staff_member or c.branch.staff_member == staff_member) : false
            end
          end
        end
        r.include?(@controller.to_sym) || r.include?(@controller.split("/")[0].to_sym)
      end
    end #User
  end
end
#            Kernel.qualified_const_get(controller.to_s.split(/_/).map{|seg| 
#                                         seg.capitalize
#                                     }.join).callable_actions.to_a.each{|action|
