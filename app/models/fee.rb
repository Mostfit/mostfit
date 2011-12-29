class Fee
  include DataMapper::Resource
  
  # PAYABLE is a hash which enables us to call the correct function on the correct model
  # to determine which date the fee is payable on.
  # It is of the format
  # [[:payable_on, Model, FunctionModel, function]] where Model is the class that it is applicable on and FunctionModel is the class
  # on which to call the function.
  # We have this difference to handle cases where the fee is applicable on an Insurance Policy but is payable on the loan application date


  PAYABLE = [
             [:loan_applied_on, Loan, :applied_on], 
             [:loan_approved_on, Loan, :approved_on],
             [:loan_disbursal_date, Loan, :disbursal_date],
             [:loan_scheduled_first_payment_date, Loan, :scheduled_first_payment_date], 
             [:loan_first_payment_date, Loan, :first_payment_date],
             [:client_grt_pass_date, Client, :grt_pass_date], 
             [:client_date_joined, Client, :date_joined], 
             [:loan_installment_dates, Loan, :installment_dates],
             [:policy_issue_date, InsurancePolicy, :date_from],
             #[:policy_loan_application_date, InsurancePolicy, :loan_applied_on],
             #[:policy_loan_approval_date, InsurancePolicy, :loan_approved_on],
             #[:policy_loan_disbursal_date, InsurancePolicy, :loan_disbursal_date],
             [:penalty, Loan, nil]
            ]
  FeeDue        = Struct.new(:applicable, :paid, :due)
  FeeApplicable = Struct.new(:loan_id, :client_id, :fees_applicable)
  property :id,            Serial
  property :name,          String, :nullable => false
  property :percentage,    Float
  property :amount,        Integer
  property :min_amount,    Integer
  property :max_amount,    Integer
  property :payable_on,    Enum.send('[]',*PAYABLE.map{|m| m[0]}), :nullable => false
  property :overridable_by, Flag[:data_entry, :mis_manager, :admin,:staff_member]

  property :round_to,       Float
  property :rounding_style, Enum[:round, :ceil, :floor], :default => :round, :nullable => false

  has n, :loan_products, :through => Resource
  has n, :client_types, :through => Resource
  has n, :insurance_products, :through => Resource
  # anything else will have to be ruby code - sorry

  has n, :applicable_loans,              'ApplicableFee', :applicable_type => 'Loan',            :child_key => [:applicable_id]
  has n, :applicable_clients,            'ApplicableFee', :applicable_type => 'Client',          :child_key => [:applicable_id]
  has n, :applicable_insurance_policies, 'ApplicableFee', :applicable_type => 'InsurancePolicy', :child_key => [:applicable_id]

  has n, :loans,              :through => :applicable_loans
  has n, :clients,            :through => :applicable_clients
  has n, :insurance_policies, :through => :applicable_insurance_policies
  has n, :audit_trails, :auditable_type => "Fee", :child_key => ["auditable_id"]

  
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

  def Fee.fees_for_insurance_products(fees)
    fees.select {|fee| fee.payable_on.to_s =~ /policy/}
  end

  def self.payable_dates
    PAYABLE.map{|m| m[0]}
  end

  def fees_for(loan)
    return amount if amount
    return [[min_amount || 0 , (percentage ? percentage * loan.amount : 0)].max, max_amount || (1.0/0)].min.round_to_nearest(round_to, rounding_style)
  end

  # Calculate the amount to be levied depending on the object type
  def amount_for(obj)
    return amount if amount
    if obj.class == Loan or obj.class.superclass == Loan or obj.class.superclass.superclass == Loan and obj.loan_product and obj.loan_product.fees.include?(self)
      return [[min_amount || 0 , (percentage ? percentage * obj.amount : 0)].max, max_amount || (1.0/0)].min
    elsif obj.class == Client and obj.client_type and obj.client_type.fees.include?(self)
      return self.client_types.include?(obj.client_type) ? [min_amount, max_amount].max : nil
    elsif obj.class == InsurancePolicy
      return obj.premium
    end
  end
  
  # find whether the fee is applicable to an object
  def is_applicable?(obj)
    if obj.is_a?(Loan)
      obj.loan_product.fees.include?(self)
    elsif obj.is_a?(Client) and obj.client_type
      obj.client_type.fees.include?(self)
    elsif obj.is_a?(InsurancePolicy) and obj.insurance_product
      obj.insurance_product.fees.include?(self)
    end
  end
  
  # returns the applicable fees for a list of ids and applicable type. Additional params can be provided by hash
  def self.applicable(ids, hash = {}, applicable_type = 'Loan')
    date = hash.delete(:date) || Date.today
    
    query  = {:applicable_on.lte => date}
    query[:applicable_id] = ids unless ids == :all
    query[:applicable_type] = applicable_type
    query.merge!(hash)
    ApplicableFee.all(query)
  end

  # returns the paid fee for a list of ids and applicable type. Additional params can be provided by hash 
  def self.paid(ids, hash = {}, applicable_type = 'Loan')
    if ids.length > 0
      query = {:applicable_id => ids, :applicable_type => 'Loan', :applicable_on.lte => hash[:date] || Date.today}
      query.merge!(hash)
      query_str = ApplicableFee.all(query).map{|x| "(#{x.fee_id}, #{x.applicable_id})"}.join(", ")
      parent_col = ((applicable_type == 'Loan') ? "loan_id" : "client_id")
      if query_str.length > 0
        repository.adapter.query(%Q{SELECT #{parent_col}, SUM(amount) 
                                  FROM payments 
                                  WHERE (fee_id, #{parent_col}) in (#{query_str})
                                        AND deleted_at is NULL
                                  GROUP BY #{parent_col}
                              }).map{|x| [x[0], x[1]]}.to_hash
      else
        {}
      end
    else
      {}
    end
  end

  # returns any due fee for a list of ids and applicable type. Additional params can be provided by hash 
  def self.due(ids, hash={}, applicable_type = 'Loan')
    return {} if ids.blank?
    fees_applicable = self.applicable(ids, hash, applicable_type).aggregate(:applicable_id, :amount.sum).to_hash      
    fees_paid       = self.paid(ids, hash, applicable_type)
    fees = {}

    ids.each{|lid|
      applicable = fees_applicable[lid]||0
      next unless applicable
      paid      = fees_paid.key?(lid) ? fees_paid[lid] : 0
      fees[lid]  = FeeDue.new(applicable, paid, ((applicable - paid) > 0 ? (applicable - paid) : 0))
    }
    fees
  end

  def self.overdue(date=Date.today)
    fees = self.applicable(:all, :date => date).map{|app| [app.applicable_id, app.amount.to_i]}.to_hash
    paid = Payment.all(:type => :fees, :loan_id.not => nil, :received_on.lte => date).aggregate(:loan_id, :amount.sum).to_hash
    (fees - paid).reject{|lid, a| a<=0}
  end

  # faster compilation of fee collected for/by a given obj. This obj can be a branch, center, area, region or staff member
  # fee_collected_type here is relevant only for the case of staff member. This comes into play when we need all the fee collected under centers
  # managed by the staff member.
  # TODO:  rewrite it using Datamapper
  def self.collected_for(obj, from_date=Date.min_date, to_date=Date.max_date, fee_collected_type = :created)
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
      if fee_collected_type == :created
        from  = "payments p, fees f"
        where = %Q{
                  p.received_by_staff_id=#{obj.id} and p.type=3 and p.fee_id=f.id
                  and p.deleted_at is NULL and p.received_on>='#{from_date.strftime('%Y-%m-%d')}' and p.received_on<='#{to_date.strftime('%Y-%m-%d')}'
               };
      elsif fee_collected_type == :managed
        from  = "centers c, clients cl, payments p, fees f"
        where = %Q{
                  c.manager_staff_id=#{obj.id} and cl.center_id=c.id and p.client_id=cl.id and p.type=3 and p.fee_id=f.id
                  and p.deleted_at is NULL and p.received_on>='#{from_date.strftime('%Y-%m-%d')}' and p.received_on<='#{to_date.strftime('%Y-%m-%d')}'
               };
      end
    elsif obj.class==LoanProduct
      from  = "loans l, payments p, fees f"
      where = %Q{
                  l.id = p.loan_id and l.loan_product_id = #{obj.id} and l.deleted_at is NULL and p.type=3 and p.fee_id=f.id
                  and p.deleted_at is NULL and p.received_on>='#{from_date.strftime('%Y-%m-%d')}' and p.received_on<='#{to_date.strftime('%Y-%m-%d')}'
               };
    elsif obj.class==FundingLine
      from  = "loans l, payments p, fees f"
      where = %Q{
                  l.id = p.loan_id and l.funding_line_id = #{obj.id} and l.deleted_at is NULL and p.type=3 and p.fee_id=f.id
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
