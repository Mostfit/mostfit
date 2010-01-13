class Verifications < Application
  def index
    centers   = centers(session.user)
    case params[:model]
    when "clients"
      @clients  = clients(centers) 
    when "loans"
      @loans    = loans(centers)
    when "payments"
      @payments = payments(centers)
    else
      @clients_count  = clients(centers).count
      @loans_count    = loans(centers).count
      @payments_count = payments(centers).count
    end
    display "verifications/index"
  end

  def update(id)
    if ["clients", "loans", "payments"].include?(id) and params[id]
      klass = Kernel.const_get(id.singularize.capitalize)
      verifier_id = session.user.id
      ids = params[id].keys.collect{|x| x.to_i}.join(',')
      repository.adapter.execute("UPDATE #{klass.to_s.downcase.pluralize} SET verified_by_user_id=#{verifier_id.to_i} WHERE id in (#{ids})")
    end
    redirect url(:verifications)
  end

  private
  def clients(centers = nil)
    hash = {:verified_by_user_id => nil}
    hash[:center_id] = centers.map{|x| x.id} if centers
    Client.all(hash)
  end
  
  def loans(centers = nil, type = :objects)
    hash = {:verified_by_user_id => nil}
    hash[:client_id] = Client.all(:center_id => centers.map{|x| x.id}).map{|x| x.id} if centers
    Loan.all(hash)
  end
  
  def payments(centers = nil, type = :objects)
    hash = {:verified_by_user_id => nil}
    hash[:loan_id]   = Loan.all(:client_id => Client.all(:center_id => centers.map{|x| x.id}).map{|x| x.id}).map{|x| x.id} if centers
    Payment.all(hash)
  end

  def centers(user)
    if user.admin?
      centers = Center.all
    else
      staff = StaffMember.all(:user_id => user.id)
      if staff.length>0
        centers = staff.branches.centers
        centers << staff.centers
        centers.uniq!
      end
    end
    centers
  end
end
