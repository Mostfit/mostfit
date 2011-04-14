module FeesContainer
  # levy fees on given object
  def levy_fees
    existing_fees = self.fees
    @payable_models ||= Fee::PAYABLE.map{|m| [m[0], [m[1], m[2]]]}.to_hash

    Fee.all.map{|fee|
      if @payable_models.key?(fee.payable_on)
        klass, payable_date_method = @payable_models[fee.payable_on]
        next unless self.respond_to?(payable_date_method)
        date = self.send(payable_date_method)
        amount = fee.amount_for(self)
        next unless amount
        unless ApplicableFee.first(:applicable_id => self.id, :applicable_type => klass, :applicable_on => date, :fee => fee)
          af = ApplicableFee.new(:amount => amount, :applicable_on => date, :fee => fee,
                                 :applicable_id => self.id, :applicable_type => klass)
          af.save
          af
        else
          nil
        end
      end
    }.compact
  end

  # returns fees that are applied for the client
  def fees
<<<<<<< HEAD
<<<<<<< HEAD
    Fee.all(:id => ApplicableFee.all(:applicable_id => self.id, :applicable_type => self.class.to_s).aggregate(:fee_id))
=======
    Fee.all(:id => ApplicableFee.all(:applicable_id => self.id, :applicable_type => get_class).aggregate(:fee_id))
>>>>>>> Added fees container and coresponding hooks in Client and Loan model
=======
    Fee.all(:id => ApplicableFee.all(:applicable_id => self.id, :applicable_type => self.class.to_s).aggregate(:fee_id))
>>>>>>> Added fees container and coresponding hooks in Client and Loan model
  end
  
  # return total fee due for this client including fees applicable to client, loan and insurance policies
  def total_fees_due(date=Date.today)
    fees = 0

<<<<<<< HEAD
<<<<<<< HEAD
    fees += (ApplicableFee.all(:applicable_type => self.class.to_s, :applicable_id => self.id, :applicable_on.lte => date).aggregate(:amount.sum) || 0)
=======
    fees += (ApplicableFee.all(:applicable_type => get_class, :applicable_id => self.id, :applicable_on.lte => date).aggregate(:amount.sum) || 0)
>>>>>>> Added fees container and coresponding hooks in Client and Loan model
=======
    fees += (ApplicableFee.all(:applicable_type => self.class.to_s, :applicable_id => self.id, :applicable_on.lte => date).aggregate(:amount.sum) || 0)
>>>>>>> Added fees container and coresponding hooks in Client and Loan model

    if self.class == Client
      if self.loans.length > 0
        fees += (ApplicableFee.all(:applicable_type => 'Loan',   :applicable_id => self.loans.aggregate(:id), :applicable_on.lte => date).aggregate(:amount.sum) || 0)
      end
      
      if self.insurance_policies.length > 0
        fees += (ApplicableFee.all(:applicable_type => 'InsurancePolicy', :applicable_id => self.insurance_policies.aggregate(:id), :applicable_on.lte => date).aggregate(:amount.sum) || 0)
      end
    end
    fees
  end

  # return total fee paid for this client
  def total_fees_paid(date=Date.today)
<<<<<<< HEAD
<<<<<<< HEAD
    Payment.all(:type => :fees, :client => self, :received_on.lte => date).sum(:amount) || 0
=======
    if self.class == Client
      Payment.all(:type => :fees, :client => self, :received_on.lte => date).sum(:amount) || 0
    elsif self.is_a?(Loan)
      Payment.all(:type => :fees, :loan   => self, :received_on.lte => date).sum(:amount) || 0
    elsif self.is_a?(InsurancePolicy)
      Payment.all(:type => :fees, :client => self.client, :received_on.lte => date, :fee_id => ApplicableFee.all(:applicable_type => 'InsurancePolicy', :applicable_id => self.id).aggregate(:fee_id)).sum(:amount) || 0
    end
>>>>>>> Added fees container and coresponding hooks in Client and Loan model
=======
    Payment.all(:type => :fees, :client => self, :received_on.lte => date).sum(:amount) || 0
>>>>>>> Added fees container and coresponding hooks in Client and Loan model
  end

  def total_fees_payable_on(date = Date.today)
    # returns one consolidated number
    total_fees_due(date) - total_fees_paid(date)
  end

  def fees_payable_on(date = Date.today)
    # returns a hash of fee type and amounts
    scheduled_fees = fee_schedule.reject{|k,v| k > date}.values.inject({}){|s,x| s+=x}
    (scheduled_fees - (fees_paid.reject{|k,v| k > date}.values.inject({}){|s,x| s+=x})).reject{|k,v| v<=0}
  end

  # returns a hash of fees paid which has keys as dates and values as {fee => amount}  
  def fees_paid
    @fees_payments = {}
    payments(:type => :fees, :order => [:received_on], :loan => nil).each do |p|
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
<<<<<<< HEAD
<<<<<<< HEAD
    ApplicableFee.all(:applicable_id => self.id, :applicable_type => self.class.to_s).map{|af|
=======
    ApplicableFee.all(:applicable_id => self.id, :applicable_type => get_class).map{|af|
>>>>>>> Added fees container and coresponding hooks in Client and Loan model
=======
    ApplicableFee.all(:applicable_id => self.id, :applicable_type => self.class.to_s).map{|af|
>>>>>>> Added fees container and coresponding hooks in Client and Loan model
      @fee_schedule[af.applicable_on] ||= {}
      @fee_schedule[af.applicable_on][af.fee] = af.amount
    }
    @fee_schedule
  end

  def fee_payments
    @fees_payments = {}
  end
<<<<<<< HEAD
<<<<<<< HEAD
=======

  private
  def get_class
    if self.is_a?(Client)
      'Client'
    elsif self.is_a?(InsurancePolicy)
      'InsurancePolicy'
    elsif self.is_a?(Loan)
      'Loan'
    end
  end
>>>>>>> Added fees container and coresponding hooks in Client and Loan model
=======
>>>>>>> Added fees container and coresponding hooks in Client and Loan model
end
