module Misfit
  module Extensions
    module Browse
      def self.included(base)
        Merb.logger.info "Included Misfit::Extensions::Browse by #{base}"
        base.show_action(:centers_paying_today)
        base.show_action(:regions)
      end

      def before
        if session.user.staff_member
          @staff_member = session.user.staff_member
          if branch = Branch.all(:manager => @staff_member)
            true
          else
            @centers = Center.all(:manager => @staff_member)
            @template = 'browse/for_staff_member'
          end
        end
      end

      def centers_paying_today
        @date = params[:date] ? Date.parse(params[:date]) : Date.today
        center_ids = LoanHistory.all(:date => Date.today).map{|x| x.center_id}.uniq
        # restrict branch manager and center managers to their own branches
        if session.user.role==:staff_member
          st = session.user.staff_member
          center_ids = ([st.branches.centers.map{|x| x.id}, st.centers.map{|x| x.id}].flatten.compact) & center_ids
        end

        center_ids = ["NULL"] if center_ids.length==0
        center_ids = center_ids.join(',')
        client_ids = repository.adapter.query(%Q{SELECT c.id FROM clients c WHERE c.center_id IN (#{center_ids})})
        @data = repository.adapter.query(%Q{SELECT c.id as id, c.branch_id as branch_id, c.name name, SUM(lh.principal_due) pd, SUM(lh.interest_due) intd, 
                                                   SUM(lh.principal_paid) pp, SUM(lh.interest_paid) intp
                                        FROM loan_history lh, centers c
                                        WHERE lh.center_id IN (#{center_ids}) AND lh.date='#{@date.strftime('%Y-%m-%d')}' AND c.id=lh.center_id
                                        GROUP BY lh.center_id ORDER BY c.name}).group_by{|x| x.branch_id}
        @disbursals = Loan.all(:client_id => client_ids, :scheduled_disbursal_date => @date)
        render :template => 'dashboard/today'
      end
    end # Browse

    module User
      CUD_Actions =["create", "new", "edit", "update", "destroy"]
      CR_Actions =["create", "new", "index", "show"]
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

      def can_approve?(obj)        
        if staff_member
          if obj.class==Client
            return (obj.center.branch.manager == staff_member)
          elsif obj.class==Loan or Loan.descendants.map{|x| x}.include?(obj.class)
            return (obj.client.center.branch.manager == staff_member)
          end
          retrun false
        end
        return false if role == :read_only
        return true
      end

      def additional_checks
        id = @route[:id].to_i
        staff_member = self.staff_member
        model = Kernel.const_get(@model.to_s.split("/")[-1].camelcase)
        if model == Loan
          l = Loan.get(id)
          return ((l.client.center.manager == staff_member) or (l.client.center.branch.manager == staff_member))
        elsif model == StaffMember
          #Trying to check his own profile? Allowed!
          return true if staff_member.id==id
          st = StaffMember.get(id)
          #Allow access to this staff member if it is his branch manager
          # do not allow a staff member any other staff member access
          return false if staff_member.branches.length==0
          return(st.centers.branches.manager.include?(staff_member))
        elsif model == Client
          c = Client.get(id)
          return ((c.center.manager == staff_member) or (c.center.branch.manager == staff_member))
        elsif model == Branch
          branch = Branch.get(id)
          return ((branch.manager == staff_member) or (branch.centers.manager.include?(staff_member)))
       elsif model == Center
          center = Center.get(id)
          return true if center.manager == staff_member
          return center.branch.manager == staff_member
        elsif model.respond_to?(:relationships) and model.relationships.include?(:manager)
          o = model.get(id)
          return true if o.manager == staff_member
        elsif [Comment, Document, InsurancePolicy, InsuranceCompany].include?(model)
          reutrn true
        else
          return false
        end
      end

      def is_manager_of?(obj)
        staff = self.staff_member      
        return true if obj and obj.new?
        if obj.class==Client and not (obj.center.manager==staff or obj.center.branch.manager==staff)
          return false
        elsif obj.class==Center and not (obj.manager==staff or obj.branch.manager==staff)
          return false
        elsif obj.class==Loan   and not (obj.client.center.manager==staff or obj.client.center.branch.manager==staff)
          return false
        end
        return true
      end

      
      def _can_access?(route,params = nil)
        # more garbage
        return true if role == :admin
        return true if route[:controller] == "graph_data" or route[:controller] == "info"
        return true if route[:controller] == "users" and route[:action] == "change_password"
        @route = route
        @controller = (route[:namespace] ? route[:namespace] + "/" : "" ) + route[:controller]
        @model = route[:controller].singularize.to_sym
        @action = route[:action]
        return true if @action == "redirect_to_show"
        if @controller=="documents" and CUD_Actions.include?(@action)
          return true  if params[:parent_model]=="Client"
          return false if params[:parent_model]=="Mfi"    and (role!=:admin or role!=:mis_manager)
          return true  if params[:parent_model]=="Center" and (role==:staff_member or role==:mis_manager or role==:admin)
          return true  if params[:parent_model]=="Branch" and (role==:staff_member and Branch.get(params[:parent_id]).manager==staff_member)
          return false
        end
        r = (access_rights[@action.to_s.to_sym] or access_rights[:all])
        return false if @action == "approve" and role == :data_entry
        return false if role == :read_only and CUD_Actions.include?(@action) 
        return false if r.nil?
        if staff_member
          # Only allow branch managers to edit or create a new staff member, branch or a center
          if ["staff_members", "branches", "centers"].include?(@controller) and CUD_Actions.include?(@action)
            return staff_member.branches.length>0
          end

          return additional_checks if @route.has_key?(:id) and @route[:id]
          if params and params[:branch_id] and not params[:branch_id].blank?
            b = Branch.get(params[:branch_id])
            return (b.manager == staff_member or b.centers.managers.include?(staff_member))
          end

          if params and params[:center_id]
            c = Center.get(params[:center_id])
            return ((c.manager == staff_member or c.branch.manager == staff_member))
          end

          if params and params[:client_id]
            c = Client.get(params[:client_id])
            return ((c.center.manager == staff_member or c.center.branch.manager == staff_member))
          end
          
          if params and params[:loan_id]
            l = Loan.get(params[:loan_id])
            return ((l.client.center.manager == staff_member or l.client.center.branch.manager == staff_member))
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
