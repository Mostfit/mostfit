module FeesContainer
  # levy fees on given object
  def levy_fees(args = {})
    @payable_models ||= Fee::PAYABLE.map{|m| [m[0], [m[1], m[2]]]}.to_hash
    apfees = ApplicableFee.all(:applicable_id => self.id, :applicable_type => get_class.to_s)
    apfees.destroy! if args.is_a?(Hash) and args[:override] # don't know why args is true if nothing is sent. data-mapper?

    if self.is_a?(Loan) and (not apfees.empty?) 
      # if this loan has some applicable fees, then we only update the date, nothing else
      apfees.each do |af|
        method = @payable_models[af.fee.payable_on][1]
        if method
          date = (self.send(method) if self.respond_to?(method))|| (self.send("scheduled_#{method}") if self.respond_to?("scheduled_#{method}"))
        end
        next unless date
        af.applicable_on = date
        af.save
        af
      end
    else
      Fee.all.select{|fee| @payable_models.key?(fee.payable_on)  and fee.is_applicable?(self)}.map{|fee|
        klass, payable_date_method = @payable_models[fee.payable_on]
        next unless payable_date_method
        next unless self.respond_to?(payable_date_method)
        date = self.send(payable_date_method) || (self.send("scheduled_#{payable_date_method}") if self.respond_to?("scheduled_#{payable_date_method}"))
        amount = fee.amount_for(self)
        next unless amount and date
        unless ApplicableFee.first(:applicable_id => self.id, :applicable_type => klass, :applicable_on => date, :fee => fee)
          af = ApplicableFee.new(:amount => amount, :applicable_on => date, :fee => fee,
                                 :applicable_id => self.id, :applicable_type => klass)
          af.save
          af
        end
        
      }
    end
  end

  # returns fees that are applied for the client
  def fees
    Fee.all(:id => ApplicableFee.all(:applicable_id => self.id, :applicable_type => get_class).aggregate(:fee_id))
  end
  
  # return total fee due for this client including fees applicable to client, loan and insurance policies
  def total_fees_due(date=Date.today)
    total_fees_applicable(date) - total_fees_paid(date)
  end

  def total_fees_applicable(date=Date.today)
    (ApplicableFee.all(:applicable_type => get_class, :applicable_id => self.id, :applicable_on.lte => date).aggregate(:amount.sum) || 0)
  end

  # return total fee paid for this client
  def total_fees_paid(date=Date.today)
    fee_ids = ApplicableFee.all(:applicable_type => self.get_class, :applicable_id => self.id).aggregate(:fee_id)
    return 0 if fee_ids.length == 0

    if self.is_a?(Client)      
      Payment.all(:type => :fees, :client => self, :received_on.lte => date, :loan_id => nil, :fee_id => fee_ids).sum(:amount) || 0
    elsif self.is_a?(Loan)
      Payment.all(:type => :fees, :loan => self, :received_on.lte => date, :fee_id => fee_ids).sum(:amount) || 0
    elsif self.is_a?(InsurancePolicy)
      Payment.all(:type => :fees, :client => self.client, :received_on.lte => date, :fee_id => fee_ids).sum(:amount) || 0
    end      
  end

  def total_fees_payable_on(date = Date.today)
    # returns one consolidated number
    [total_fees_applicable(date) - total_fees_paid(),0].max
  end

  def fees_payable_on(date = Date.today)
    # returns a hash of fee type and amounts
    scheduled_fees = fee_schedule.reject{|k,v| k > date}.values.inject({}){|s,x| s+=x}
    (scheduled_fees - (fees_paid.values.inject({}){|s,x| s+=x})).reject{|k,v| v<=0}
  end

  # returns a hash of fees paid which has keys as dates and values as {fee => amount}  
  def fees_paid(date = Date.today)
    @fees_payments = {}
    Payment.all(:type => :fees, :client => (self.class == Client ? self : self.client), :loan => (self.is_a?(Loan) ? self : nil), :received_on.lte => date, :order => [:received_on],
                :fee_id => ApplicableFee.all(:applicable_type => self.get_class, :applicable_id => self.id).aggregate(:fee_id)).each do |p|
      @fees_payments += {p.received_on => {p.fee => p.amount}}
    end
    @fees_payments
  end

  def fees_paid?
    total_fees_paid >= total_fees_due
  end
  
  # returns a hash of fee schedule which has keys as dates and values as {fee => amount}
  def fee_schedule
    @fee_schedule = {}
    ApplicableFee.all(:applicable_id => self.id, :applicable_type => get_class).map{|af|
      @fee_schedule[af.applicable_on] ||= {}
      @fee_schedule[af.applicable_on][af.fee] = af.amount
    }
    @fee_schedule
  end

  def fee_payments
    @fees_payments = {}
  end

  def get_class
    if self.is_a?(Client)
      'Client'
    elsif self.is_a?(InsurancePolicy)
      'InsurancePolicy'
    elsif self.is_a?(Loan)
      'Loan'
    end
  end
end
