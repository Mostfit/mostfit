class Fee
  include DataMapper::Resource
  
  PAYABLE = [:loan_applied_on, :loan_approved_on, :loan_disbursal_date, :loan_scheduled_first_payment_date, :loan_first_payment_date, :client_grt_pass_date, :client_date_joined, :loan_installment_dates]
  FeeDue        = Struct.new(:applicable, :paid, :due)
  FeeApplicable = Struct.new(:loan_id, :client_id, :fees_applicable)
  property :id,            Serial
  property :name,          String, :nullable => false
  property :percentage,    Float
  property :amount,        Integer
  property :min_amount,    Integer
  property :max_amount,    Integer
  property :payable_on,    Enum.send('[]',*PAYABLE), :nullable => false

  has n, :loan_products, :through => Resource
  has n, :client_types, :through => Resource
  # anything else will have to be ruby code - sorry
  
  validates_with_method :amount_is_okay
  validates_with_method :min_lte_max
  
  def amount_is_okay
    return true if (amount or percentage)
    return [false, "Either an amount or a percentage must be specified"]
  end

  def min_lte_max
    return true if (min_amount and max_amount and min_amount <= max_amount) or (min_amount.nil? or max_amount.nil?)
    return [false, "Minimum amount must be less than maximum amount"]
  end

  def description
    desc =  "#{name}: "
    desc += "#{percentage*100} %" if percentage and percentage>0
    desc += " Amount Rs. #{amount}" if amount
    if min_amount and max_amount and max_amount!=min_amount
      desc += " Subject to a minimum of  Rs. #{min_amount}" if min_amount
      desc += ", maximum of Rs. #{max_amount}" if max_amount
    end
    desc
  end

  def self.payable_dates
    PAYABLE
  end

  def fees_for(loan)
    return amount if amount
    return [[min_amount || 0 , (percentage ? percentage * loan.amount : 0)].max, max_amount || (1.0/0)].min
  end
  
  def self.applicable(loan_ids)    
    loan_ids = loan_ids.length>0 ? loan_ids.join(",") : "NULL"
    payables = Fee.properties[:payable_on].type.flag_map
    applicables = repository.adapter.query(%Q{
                                SELECT l.id loan_id, l.client_id client_id, 
                                       if(f.amount>0, convert(f.amount, decimal), convert(l.amount*f.percentage, decimal)) fees_applicable, 
                                       f.payable_on payable_on                                       
                                FROM loan_products lp, fee_loan_products flp, fees f, loans l 
                                WHERE flp.fee_id=f.id AND flp.loan_product_id=lp.id AND lp.id=l.loan_product_id AND l.id IN (#{loan_ids});})
    fees = []
    applicables.each{|fee|
      if payables[fee.payable_on]==:loan_installment_dates
        installments = loans.find{|x| x.id==fee.loan_id}.installment_dates.reject{|x| x>Date.today}.length
        fees.push(FeeApplicable.new(fee.loan_id, fee.client_id, fee.fees_applicable.to_i * installments))
      else
        fees.push(FeeApplicable.new(fee.loan_id, fee.client_id, fee.fees_applicable))
      end
    }
    fees
  end

  def self.paid(loan_ids)
    client_ids = Loan.all(:fields => [:id, :client_id], :id => loan_ids).map{|x| x.client_id}.uniq
    client_ids = client_ids.length>0 ? client_ids.join(",") : "NULL"
    repository.adapter.query(%Q{
                                SELECT loan_id, client_id, amount
                                FROM payments p
                                WHERE p.client_id IN (#{client_ids}) AND p.type=3 AND deleted_at is NULL;})
  end

  def self.due(loan_ids)
    fees_applicable = self.applicable(loan_ids)
    fees_paid       = self.paid(loan_ids)
    fees = {}
    loan_ids.each{|lid|
      applicable = fees_applicable.find{|x| x.loan_id==lid}
      next if not applicable
      paid      = fees_paid.find_all{|x| x.loan_id==lid}
      paid      = (paid and paid.length>0) ? paid.map{|x| x.amount.to_i}.inject(0){|s,x| s+=x} : 0
      fees[lid]  = FeeDue.new((applicable ? applicable.fees_applicable.to_i : 0), paid, (applicable ? applicable.fees_applicable : 0) - paid)
    }
    fees
  end

   # faster compilation of fee collected for/by a given obj. This obj can be a branch, center, area, region or staff member
  def self.collected_for(obj, from_date=Date.min_date, to_date=Date.max_date)
    if obj.class==Branch
      from  = "branches b, centers c, clients cl, payments p, fees f"
      where = %Q{
                  b.id=#{obj.id} and c.branch_id=b.id and cl.center_id=c.id and p.client_id=cl.id and p.type=3 and p.fee_id=f.id
                  and p.deleted_at is NULL and p.received_on>='#{from_date.strftime('%Y-%m-%d')}' and p.received_on<='#{to_date.strftime('%Y-%m-%d')}'
               };
    elsif obj.class==Center
      from  = "centers c, clients cl, payments p, fees f"
      where = %Q{
                  c.id=#{obj.id} and cl.center_id=c.id and p.client_id=cl.id and p.type=3 and p.fee_id=f.id
                  and p.deleted_at is NULL and p.received_on>='#{from_date.strftime('%Y-%m-%d')}' and p.received_on<='#{to_date.strftime('%Y-%m-%d')}'
               };
    elsif obj.class==ClientGroup
      from  = "client_groups cg, clients cl, payments p, fees f"
      where = %Q{
                 cg.id=#{obj.id} and cg.id=c.client_group_id and p.client_id=cl.id and p.type=3 and p.fee_id=f.id
                 and p.deleted_at is NULL and p.received_on>='#{from_date.strftime('%Y-%m-%d')}' and p.received_on<='#{to_date.strftime('%Y-%m-%d')}'
              };
    elsif obj.class==Client
      from  = "clients cl, payments p, fees f"
      where = %Q{
                 p.client_id=cl.id and p.type=3 and p.fee_id=f.id
                 and p.deleted_at is NULL and p.received_on>='#{from_date.strftime('%Y-%m-%d')}' and p.received_on<='#{to_date.strftime('%Y-%m-%d')}'
              };
    elsif obj.class==Area
      from  = "areas a, branches b, centers c, clients cl, payments p, fees f"
      where = %Q{
                  a.id=#{obj.id} and a.id=b.area_id and c.branch_id=b.id and cl.center_id=c.id 
                  and p.client_id=cl.id and p.type=3 and p.fee_id=f.id
                  and p.deleted_at is NULL and p.received_on>='#{from_date.strftime('%Y-%m-%d')}' and p.received_on<='#{to_date.strftime('%Y-%m-%d')}'
               };
    elsif obj.class==Region
      from  = "regions r, areas a, branches b, centers c, clients cl, payments p, fees f"
      where = %Q{
                  r.id=#{obj.id} and r.id=a.region_id and a.id=b.area_id and c.branch_id=b.id and cl.center_id=c.id 
                  and p.client_id=cl.id and p.type=3 and p.fee_id=f.id
                  and p.deleted_at is NULL and p.received_on>='#{from_date.strftime('%Y-%m-%d')}' and p.received_on<='#{to_date.strftime('%Y-%m-%d')}'
               };
    elsif obj.class==StaffMember
      from  = "payments p, fees f"
      where = %Q{
                  p.received_by_staff_id=#{obj.id} and p.type=3 and p.fee_id=f.id
                  and p.deleted_at is NULL and p.received_on>='#{from_date.strftime('%Y-%m-%d')}' and p.received_on<='#{to_date.strftime('%Y-%m-%d')}'
               };
    end
    repository.adapter.query(%Q{
                             SELECT SUM(p.amount) amount, f.name name
                             FROM #{from}
                             WHERE #{where}
                             GROUP BY p.fee_id
                           }).map{|x| [x.name, x.amount.to_i]}.to_hash
  end


end
