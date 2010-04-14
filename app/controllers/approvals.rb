class Approvals < Application
  def index
    clients
    loans
    payments
    display "approvals/index"
  end

  def update(id)
    if ["clients", "loans", "payments"].include?(id) and params[id]
      klass = Kernel.const_get(id.singularize.capitalize)
      verifier_id = session.user.id
      klass.all(:id => params[id].keys).each{|obj|
        obj.verified_by_user_id = approver_id
        obj.save
      }
    end
    redirect url(:approvals)
  end

  private
  def clients
    if session.user.admin?
      @clients = Client.all(:approved_by_user_id => nil)
    elsif session.user.staff_member
      @clients = managed_centers(user).clients
    else
      @clients= []
    end
  end
  
  def clients
    if session.user.admin?
      @loans = Loan.all(:approved_by_user_id => nil)
    elsif session.user.staff_member
      @loans = managed_centers(user).clients.loans
    else
      @loans= []
    end
  end
  
  def payments
    if session.user.admin?
      @payments = Payment.all(:approved_by_user_id => nil)
    elsif session.user.staff_member
      @payments = managed_centers(user).clients.loans.payments
    else
      @payments= []
    end

  end

  def managed_centers(user)
    staff = StaffMember.all(:user_id => user.id)
    centers = []
    if staff.length>0
      centers << staff.branches.centers.map{|x| x.id}
      centers << staff.centers.map{|x| x.id}
      centers.uniq!
    end
    centers
  end
end
