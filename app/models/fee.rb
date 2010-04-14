class Fee
  include DataMapper::Resource
  
  PAYABLE = [:loan_applied_on, :loan_approved_on, :loan_disbursal_date, :loan_scheduled_first_payment_date, :loan_first_payment_date, :client_grt_pass_date, :client_date_joined]
  FeeDue = Struct.new(:applicable, :payed, :due)

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
    repository.adapter.query(%Q{
                                SELECT l.id loan_id, l.client_id client_id, 
                                       sum(if(f.amount>0, convert(f.amount, decimal), convert(l.amount*f.percentage, decimal))) fees_applicable
                                FROM loan_products lp, fee_loan_products flp, fees f, loans l 
                                WHERE flp.fee_id=f.id AND flp.loan_product_id=lp.id AND lp.id=l.loan_product_id AND l.id IN (#{loan_ids})
                                GROUP BY loan_id;})
  end

  def self.payed(loan_ids, client_ids)
    loan_ids   = loan_ids.length>0 ? loan_ids.join(",") : "NULL"
    client_ids = client_ids.length>0 ? client_ids.join(",") : "NULL"
    repository.adapter.query(%Q{
                                SELECT loan_id, client_id, amount, id
                                FROM payments p
                                WHERE (p.loan_id IN (#{loan_ids}) OR p.client_id IN (#{client_ids})) AND p.type=3 AND deleted_at is NULL;})
  end
  
  def self.due(loan_ids)
    fees_applicable = self.applicable(loan_ids)
    fees_payed      = self.payed(loan_ids, fees_applicable.map{|x| x.client_id})
    fees = {}
    loan_ids.each{|lid|
      applicable = fees_applicable.find{|x| x.loan_id==lid}
      next if not applicable
      payed      = fees_payed.find_all{|x| 
        (x and x.loan_id==lid) or (x and x.client_id==applicable.client_id)
      }.collect{|x| x.amount}.inject(0){|s,x| s+=x}
      fees[lid]  = FeeDue.new((applicable ? applicable.fees_applicable : 0), payed, (applicable ? applicable.fees_applicable : 0) - payed)
    }
    fees
  end
end
