class ApplicableFee
  include DataMapper::Observer
  include DataMapper::Resource

  observe Loan, Client, InsurancePolicy

  FeeApplicableTypes = ['Loan', 'Client', 'InsurancePolicy']

  property :id, Serial
  property :applicable_id,   Integer, :index => true, :nullable => false
  property :applicable_type, Enum.send('[]', *FeeApplicableTypes), :index => true, :nullable => false
  property :applicable_on,    Date, :nullable => true
  property :fee_id,          Integer, :index => true, :nullable => false
  property :amount,          Float,   :index => true, :nullable => false

  property :waived_off_on,   Date, :nullable => true
  property :waived_off_by_id,Integer, :nullable => true

  belongs_to :fee
  belongs_to :waived_off_by,    'StaffMember',     :child_key => [:waived_off_by_id]
  belongs_to :loan,             'Loan',            :child_key => [:applicable_id]
  belongs_to :client,           'Client',          :child_key => [:applicable_id]
  belongs_to :insurance_policy, 'InsurancePolicy', :child_key => [:applicable_id]
  
  def loan
    Loan.get(self.applicable_id) if applicable_type == 'Loan'
  end

  def parent
    Kernel.const_get(self.applicable_type).get(self.applicable_id)
  end

  def self.levy_fees(obj)
    existing_fees = obj.fees
    @@payable_models ||= Fee::PAYABLE.map{|m| [m[0], [m[1], m[2]]]}.to_hash

    Fee.all.map{|fee|
      if @@payable_models.key?(fee.payable_on)
        klass, payable_date_method = @@payable_models[fee.payable_on]
        next unless obj.respond_to?(payable_date_method)
        date = obj.send(payable_date_method)
        p date
        amount = fee.amount_for(obj)
        next unless amount
        unless first(:applicable_id => obj.id, :applicable_type => klass, :applicable_on => date, :fee => fee)
          af = new(:amount => amount, :applicable_on => date, :fee => fee,
                   :applicable_id => obj.id, :applicable_type => klass)
          af.save
          af
        else
          nil
        end
      end
    }.compact
  end
end
