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
      approver_id = session.user.id
      klass.all(:id => params[id].keys).each{|obj|
        obj.approved_by_user_id = approver_id
        obj.save
      }
    end
    redirect url(:approvals)
  end

  private
  def clients
    @clients = Client.all(:approved_by_user_id => 0)
  end
  
  def loans
    @loans = Loan.all(:approved_by_staff_id => nil)
  end
  
  def payments
    @payments = Payment.all(:approved_by_user_id => 0)    
  end
end
