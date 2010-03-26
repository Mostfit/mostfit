module Merb
  module ReportsHelper
    def get_printer_url
      request.env["REQUEST_URI"] + (request.env["REQUEST_URI"].index("?") ? "&" : "?") + "layout=printer"
    end

    def branches
      if session.user.role==:staff_member
        [session.user.staff_member.centers.branches, session.user.staff_member.branches].flatten
      else
        Branch.all
      end
    end
    
    def centers(branch_id)
      centers = if session.user.role==:staff_member
                  [session.user.staff_member.centers, session.user.staff_member.branches.centers].flatten
                elsif branch_id and not branch_id.blank?
                  Center.all(:branch_id => branch_id, :order => [:name])
                else 
                  Center.all(:order => [:name])
                end      
      centers.map{|x| [x.id, "#{x.branch.name} -- #{x.name}"]}
    end

    def staff_members      
      staff_members   =  if session.user.role==:staff_member
                           StaffMember.all(:id => session.user.staff_member.id)
                         else
                           StaffMember.all
                         end      
      staff_members.map{|x| [x.id, x.name]}
    end

    
  end
end # Merb
