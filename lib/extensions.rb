module Misfit
  module Extensions
    module User
      CUD_Actions =["create", "new", "edit", "update", "destroy", "approve", "disburse", "reject", "suggest_write_off", "write_off_suggest", "write_off", "write_off_reject"]
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

      def additional_checks
        id = @route[:id].to_i
        model = Kernel.const_get(@model.to_s.split("/")[-1].camelcase)
        if model == StaffMember
          #Trying to check his own profile? Allowed!
          return(true) if @staff.id==id
          st = StaffMember.get(id)
          # Allow access to this staff member if it is his branch manager
          # do not allow a staff member any other staff member access
          return false if @staff.branches.length==0 and @staff.areas.length==0 and @staff.regions.length==0 
          # Only allow branch managers to edit or create a new staff member
          return is_manager_of?(st.centers.branches)
        elsif model == Branch
          branch = Branch.get(id)
          if [:delete].include?(@action.to_sym)
            return (@staff.areas.length>0 or @staff.regions.length>0)
          elsif @action.to_sym==:edit
            return is_manager_of?(branch)
          else
            return(is_manager_of?(branch) or branch.centers.manager.include?(@staff))
          end
        elsif [Comment, Document, InsurancePolicy, InsuranceCompany, Cgt, Grt, AuditTrail].include?(model)
          reutrn true
        elsif model.respond_to?(:get)
          return is_manager_of?(model.get(id))
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
        return false unless obj
        if obj.class == Region
          return(obj.manager == @staff ? true : false)
        elsif obj.class == Area
          return(obj.manager == @staff or is_manager_of?(obj.region))
        elsif obj.class == Branch
          return(obj.manager == @staff or is_manager_of?(obj.area))
        elsif obj.class == Center
          return(obj.manager == @staff or is_manager_of?(obj.branch))
        elsif obj.class == Client
          return(is_manager_of?(obj.center))
        elsif obj.class == ClientGroup
          return(obj.center.manager == @staff or is_manager_of?(obj.center))
        elsif obj.class == Loan or obj.class.superclass == Loan or obj.class.superclass.superclass == Loan
          return(is_manager_of?(obj.client.center))
        elsif obj.class == StaffMember
          return true if obj == @staff 
          #branch manager needs access to the its Center managers
          return(is_manager_of?(obj.centers)) if @staff.branches.count > 0
          #area manager needs access to the its branch managers and center managers
          return(is_manager_of?(obj.branches) or is_manager_of?(obj.centers)) if @staff.areas.count > 0
          #region manager needs access to the its area manager, branch managers and center managers
          return(is_manager_of?(obj.areas) or is_manager_of?(obj.branches) or is_manager_of?(obj.centers)) if @staff.regions.count > 0
          return false
        elsif obj.respond_to?(:map)
          return(obj.map{|x| is_manager_of?(x)}.uniq.include?(true))
        else
          return false
        end
      end
      
      def allow_read_only
        return false if CUD_Actions.include?(@action)
        return true if @controller=="admin" and @action=="index"
        return access_rights[:all].include?(@controller.to_sym)
      end
      
      def _can_access?(route, params = nil)       
        user_role = self.role
        return true  if user_role == :admin
        return false if route[:controller] == "journals" and route[:action] == "edit"
        return true  if route[:controller] == "users" and route[:action] == "change_password"
        return false if (user_role == :read_only or user_role == :funder or user_role == :data_entry) and route[:controller] == "payments" and route[:action] == "delete"
        return false if (user_role != :admin) and route[:controller] == "loans" and route[:action] == "write_off_suggested"

        @route = route
        @params = params
        @controller = (route[:namespace] ? route[:namespace] + "/" : "" ) + route[:controller]
        @model = route[:controller].singularize.to_sym
        @action = route[:action]

        #read only stuff
        return allow_read_only if user_role == :read_only

        #user is a funder
        if user_role == :funder and @funder ||= Funder.first(:user_id => self.id)
          @funding_lines = @funder.funding_lines
          @funding_line_ids = @funder.funding_lines.map{|fl| fl.id}
          return(is_funder? and allow_read_only)
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
              
        if role == :data_entry 
          return ["new", "edit", "create", "update"].include?(@action) if ["clients", "loans", "client_groups"].include?(@controller)
          return (@action == "disbursement_sheet" or @action == "day_sheet") if @controller == "staff_members"
          
          if @action == "show" and @controller == "reports"
            return (@route[:report_type] == "ProjectedReport" or @route[:report_type] == "DailyReport" or @route[:report_type] == "TransactionLedger")
          end
        end
        
        if @staff
          return additional_checks if @route.has_key?(:id) and @route[:id] and not [:graph_data, :dashboard, :info].include?(@route[:controller].to_sym)
          unless CUD_Actions.include?(@action)
            return true if ["staff_members"].include?(@controller)
            return true if @controller == "regions" and @staff.regions.length > 0
            return true if @controller == "branches" and @action == "index"
            return(@staff.areas.length>0 or @staff.regions.length > 0) if @controller == "areas"
          else
            return(@staff.areas.length>0 or @staff.regions.length>0 or role == :mis_manager) if @controller == "staff_members"
            if @controller == "loans"
              if ["approve", "disburse", "reject", "suggest_write_off"].include?(@action)
                return(@staff.branches.length>0 or @staff.areas.length>0 or @staff.regions.length>0 or role == :mis_manager)
              elsif ["write_off", "write_off_suggested", "write_off_reject"].include?(@action)
                return false
              end
            end
            return false if @controller == "regions"
            return(@staff.regions.length > 0) if @controller == "areas" 
          end
          
          if [:branches, :centers, :clients, :loans].include?(@controller.to_sym) and params
            params = params.merge(@route)
            
            {:branch_id => Branch, :center_id => Center, :client_id => Client, :area_id => Area, :region_id => Region}.each{|key, klass|
              # allowing branch, center, area, region managers to create stuff inside his/her own branch/center/area/region
              return is_manager_of?(klass.get(params[key])) if params[key] and not params[key].blank?
            }

            if hash = params[@controller.singularize.to_sym] or (params[:loan_type] and not params[:loan_type].blank? and hash=params[params[:loan_type].snake_case.to_sym])
              if hash[:branch_id] and branch=Branch.get(hash[:branch_id])
                return is_manager_of?(branch)
              elsif (hash[:center_id] and center = Center.get(hash[:center_id])) or (hash[:client_id] and center = Client.get(hash[:client_id]).center)
                return is_manager_of?(center)
              elsif (hash[:area_id] and area = Area.get(hash[:area_id]))                
                return is_manager_of?(area)
              end
            else
              return false
            end
          end
          
          if @controller == "audit_trails" and params and params[:audit_for] and params[:audit_for][:controller]
            if params[:audit_for][:id]
              return is_manager_of?(Kernel.const_get(params[:audit_for][:controller].singularize.camelcase).get(params[:audit_for][:id]))
            else
              return false
            end
          end

          return is_manager_of?(Kernel.const_get(route[:for].camelcase).get(route[:id])) if @controller == "info" and route[:for] and route[:id]
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
