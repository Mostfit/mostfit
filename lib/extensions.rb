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

        if model == StaffMember
          #Trying to check his own profile? Allowed!
          return(true) if @staff.id==id
          st = StaffMember.get(id)
          # Allow access to this staff member if it is his branch manager
          # do not allow a staff member any other staff member access
          return false if @staff.branches.length==0 and @staff.areas.length==0 and @staff.regions.length==0 
          # Only allow branch managers to edit or create a new staff member
          branch = st.centers.branches.first
          return is_manager_of?(branch)
        elsif model == Branch
          branch = Branch.get(id)
          if [:delete].include?(@action.to_sym)
            return (@staff.areas.length>0 or @staff.regions.length>0)
          elsif @action.to_sym==:edit
            return is_manager_of(branch)
          else
            return(is_manager_of?(branch) or branch.centers.manager.include?(@staff))
          end
        elsif [Comment, Document, InsurancePolicy, InsuranceCompany, Cgt, Grt].include?(model)
          reutrn true
        else
          return is_manager_of?(model.get(id))
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
        elsif obj.class == Loan or obj.class.superclass == Loan
          return(is_manager_of?(obj.client.center))
        elsif obj.class == StaffMember
          return(is_manager_of?(obj.centers.branches) or is_manager_of?(obj.branches) or is_manager_of?(obj.areas))
        elsif obj.class == Array
          return(obj.map{|x| is_manager_of?(x)}.uniq.include?(true))
        else
          return false
        end
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
      
      def _can_access?(route, params = nil)
        #File.open("params.txt", "a"){|f| f.puts params.inspect}
        #File.open("routes.txt", "a"){|f| f.puts route.inspect}
        # more garbage
        user_role = self.role
        return true  if user_role == :admin
        return false if route[:controller] == "journals" and route[:action] == "edit"
        return true if route[:controller] == "users" and route[:action] == "change_password"
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
       

        if role == :data_entry and @action == "index" and @controller == "staff_members" 
          return false
        end
        
        if role == :data_entry and @action == "create" and @controller == "staff_members" 
          return false
        end
        if role == :data_entry and @action == "update" and @controller == "staff_members" 
          return false
        end
        if role == :data_entry and @action == "disbursement_sheet" and @controller == "staff_members" 
          return true 
        end

        if role == :data_entry and @action == "day_sheet" and @controller == "staff_members" 
          return true 
        end
      
        if role == :data_entry and @action == "show" and @controller == "reports"
          return true 
        end
        if role == :data_entry and @action == "death_count" and @controller == "clients"
          return true 
        end
        
        if @staff
          return additional_checks if @route.has_key?(:id) and @route[:id]
          unless CUD_Actions.include?(@action)
            return true if ["staff_members", "branches"].include?(@controller)
            return true if @controller == "regions" and @staff.regions.length > 0
            return(@staff.areas.length>0 or @staff.regions.length > 0) if @controller == "areas"
          else
            return(@staff.areas.length>0 or @staff.regions.length>0) if @controller == "staff_members"
            return false if @controller == "regions" and @staff.regions.length > 0
            return(@staff.regions.length > 0) if @controller == "areas"            
          end
          
          if [:branches, :centers, :clients, :loans].include?(@controller.to_sym) and CUD_Actions.include?(@action) and params
            if params[:branch_id] and not params[:branch_id].blank?
              # allowing branch and managers to create stuff inside his/her own branch/center
              return is_manager_of?(Branch.get(params[:branch_id]))
            elsif params[:center_id] and not params[:center_id].blank?
              #center
              return is_manager_of?(Center.get(params[:center_id]))
            elsif params[:client_id] and not params[:client_id].blank?
              # client
              return is_manager_of?(Client.get(params[:client_id]))
            elsif params[:area_id] and not params[:area_id].blank?
              # client
              return is_manager_of?(Area.get(params[:area_id]))
            elsif hash=params[@controller.singularize.to_sym] or (params[:loan_type] and not params[:loan_type].blank? and hash=params[params[:loan_type].snake_case.to_sym])
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
              return @staff.send(params[:audit_for][:controller]).all(:id => params[:audit_for][:id]).length > 0 ? true : false
            else
              return false
            end
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
