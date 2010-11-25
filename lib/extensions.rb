module Misfit
  module Extensions
    module User
      CUD_Actions =["create", "new", "edit", "update", "destroy"]
      CR_Actions =["create", "new", "index", "show"]
      #add hooks to before and after can_access? and can_manage? methods to override their behaviour
      # here we add hooks to see if the user can manage a particular instance of a model.
      def self.included(base)
        Merb.logger.info "Included Misfit::Extensions::User by #{base}"
        base.class_eval do
          alias :can_access? :_can_access?
          #congratulations you have over-ridden the base methods
          # you can now pollute away
        end
      end

      def can_approve?(obj)        
        if @staff or @staff ||= staff_member
          if obj.class==Client
            return (obj.center.branch.manager == @staff)
          elsif obj.class==Loan or Loan.descendants.map{|x| x}.include?(obj.class)
            return (obj.client.center.branch.manager == @staff)
          end
          retrun false
        end
        return false if role == :read_only or role == :funder or role==:data_entry
        return true
      end

      def additional_checks
        id = @route[:id].to_i
        model = Kernel.const_get(@model.to_s.split("/")[-1].camelcase)
        if model == Loan
          l = Loan.get(id)
          return ((l.client.center.manager == @staff) or (l.client.center.branch.manager == @staff))
        elsif model == StaffMember
          #Trying to check his own profile? Allowed!
          return(true) if @staff.id==id
          st = StaffMember.get(id)
          #Allow access to this staff member if it is his branch manager
          # do not allow a staff member any other staff member access
          return false if @staff.branches.length==0 and @staff.areas.length==0 and @staff.regions.length==0 
          # Only allow branch managers to edit or create a new staff member
          branch = st.centers.branches.first
          return(branch.manager==@staff or branch.area.manager==@staff or branch.area.region.manager==@staff)
        elsif model == Client
          c = Client.get(id)
          return ((c.center.manager == @staff) or (c.center.branch.manager == @staff))
        elsif model == Branch
          branch = Branch.get(id)
          if [:delete].include?(@action.to_sym)
            return (@staff.areas.length>0 or @staff.regions.length>0)
          elsif @action.to_sym==:edit
            return branch.manager == @staff
          else
            return((branch.manager == @staff) or (branch.centers.manager.include?(@staff)))
          end
       elsif model == Center
          center = Center.get(id)
          return true if center.manager == @staff
          return center.branch.manager == @staff
       elsif model == ClientGroup
          center   = model.get(id).center
          return true if center.manager == @staff
          return center.branch.manager == @staff
        elsif model.respond_to?(:relationships) and model.relationships.include?(:manager)
          o = model.get(id)
          return true if o.manager == @staff
        elsif [Comment, Document, InsurancePolicy, InsuranceCompany, Cgt, Grt].include?(model)
          reutrn true
        else
          return false
        end
      end

      def is_funder?
        allowed_controller = (access_rights[:all].include?(@controller.to_sym))
        return false unless allowed_controller
        id = @route[:id].to_i
        model = Kernel.const_get(@model.to_s.split("/")[-1].camelcase)
        if [Branch, Center, ClientGroup, Client, Loan, StaffMember, FundingLine, Funder, Portfolio].include?(model) and id>0 
          return(@funder.send(model.to_s.snake_case.pluralize, {:id => id}).length>0)
        elsif [Branch, Center, ClientGroup, Client, Loan, StaffMember, FundingLine, Funder, Portfolio].include?(model) and id==0
          return(@funder.send(model.to_s.snake_case.downcase.pluralize).length>0)
        elsif [Browse, Document, AuditTrail, Attendance, Search].include?(model)
          return true
        elsif model == Report
          return true unless @route[:report_type]
          return FUNDER_ACCESSIBLE_REPORTS.include?(@route[:report_type])
        end
        return false
     end

      def is_manager_of?(obj)
        @staff ||= self.staff_member
        return true if obj and obj.new?
        if obj.class==Client and not (obj.center.manager==@staff or obj.center.branch.manager==@staff)
          return false
        elsif obj.class==Center and not (obj.manager==@staff or obj.branch.manager==@staff)
          return false
        elsif obj.class==Loan   and not (obj.client.center.manager==@staff or obj.client.center.branch.manager==@staff)
          return false
        end
        return true
      end

      def allow_read_only
        if CUD_Actions.include?(@action)
          return false
        elsif @controller=="admin" and @action=="index"
          return true
        else
          return access_rights[:all].include?(@controller.to_sym)
        end
      end
      
      def _can_access?(route,params = nil)        
        # more garbage
        user_role = self.role
        return true  if user_role == :admin
        return false if route[:controller] == "journals" and route[:action] == "edit"
        return true if route[:controller] == "users" and route[:action] == "change_password"
        return false if (user_role == :read_only or user_role == :funder or user_role == :data_entry) and route[:controller] == "payments" and route[:action] == "delete"

        @route = route
        @controller = (route[:namespace] ? route[:namespace] + "/" : "" ) + route[:controller]
        @model = route[:controller].singularize.to_sym
        @action = route[:action]

        #read only stuff
        return allow_read_only if user_role == :read_only
        
        #user is a funder
        if user_role == :funder and @funder ||= Funder.first(:user_id => self.id)
          @funding_lines = @funder.funding_lines
          @funding_line_ids = @funder.funding_lines.map{|fl| fl.id}
          if is_funder? and allow_read_only
            return true
          else
            return false
          end
        end
        
        @staff ||= self.staff_member
        return true if @action == "redirect_to_show"
        if @controller=="documents" and CUD_Actions.include?(@action)
          return true  if params[:parent_model]=="Client"
          return false if params[:parent_model]=="Mfi"    and (role!=:admin or role!=:mis_manager)
          return true  if params[:parent_model]=="Center" and (role==:staff_member or role==:mis_manager or role==:admin)
          return true  if params[:parent_model]=="Branch" and (role==:staff_member and Branch.get(params[:parent_id]).manager==@staff)
          return false
        end

        r = (access_rights[@action.to_s.to_sym] or access_rights[:all])

        if role == :data_entry and ["clients", "loans", "client_groups"].include?(@controller)
          if ["new", "edit", "create", "update"].include?(@action)
            return true
          else
            return false            
          end
        end
        
        if @staff
          return additional_checks if @route.has_key?(:id) and @route[:id] and @controller == "controller"
          if ["staff_members", "branches"].include?(@controller)
            if not CUD_Actions.include?(@action)
              return true
            elsif (@staff.areas.length>0 or @staff.regions.length>0 or @staff.branches.length>0)
              # allowing area, region and branch managers to create staff members
              return true
            else
              return false
            end
          end
          
          if params and params[:branch_id] and not params[:branch_id].blank?
            b = Branch.get(params[:branch_id])
            if CUD_Actions.include?(@action)
              return(b.manager == @staff)
            else
              return(b.manager == @staff or b.centers.managers.include?(@staff))
            end
          end
          
          if params and params[:center_id]
            c = Center.get(params[:center_id])
            return ((c.manager == @staff or c.branch.manager == @staff))
          end

          if params and params[:client_id]
            c = Client.get(params[:client_id])
            return ((c.center.manager == @staff or c.center.branch.manager == @staff))
          end
          
          if params and params[:loan_id]
            l = Loan.get(params[:loan_id])
            return ((l.client.center.manager == @staff or l.client.center.branch.manager == @staff))
          end
          
          if params and params[:client_group_id] and ["cgts", "grts"].include?(@controller)
            cg = ClientGroup.get(params[:client_group_id])
            return ((cg.center.manager == @staff or cg.center.branch.manager == @staff))
          end
        end
        r.include?(@controller.to_sym) || r.include?(@controller.split("/")[0].to_sym)
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
