class ApplicableFee
  include DataMapper::Observer
  include DataMapper::Resource

  FeeApplicableTypes = ['Loan', 'Client', 'InsurancePolicy']

  property :id, Serial
  property :applicable_id,   Integer, :index => true, :nullable => false
  property :applicable_type, Enum.send('[]', *FeeApplicableTypes), :index => true, :nullable => false
  property :scheduled_on,    Date, :nullable => true
  property :applicable_on,   Date, :nullable => true
  property :fee_id,          Integer, :index => true, :nullable => false
  property :amount,          Float,   :index => true, :nullable => false
  property :deleted_at,      ParanoidDateTime, :nullable => true, :index => true

  property :waived_off_on,   Date, :nullable => true
  property :waived_off_by_id,Integer, :nullable => true

  belongs_to :fee
  belongs_to :waived_off_by,    'StaffMember',     :child_key => [:waived_off_by_id]
  belongs_to :loan,             'Loan',            :child_key => [:applicable_id]
  belongs_to :client,           'Client',          :child_key => [:applicable_id]
  belongs_to :insurance_policy, 'InsurancePolicy', :child_key => [:applicable_id]
  
  validates_with_method :fee_id, :method => :should_not_be_duplicate

  def loan
    Loan.get(self.applicable_id) if applicable_type == 'Loan'
  end

  def parent
    Kernel.const_get(self.applicable_type).get(self.applicable_id)
  end

  def description
    desc = "#{self.fee.name} of amount #{amount.round}"
    desc += " applicable on #{applicable_on}" if applicable_on
    desc
  end

  def should_not_be_duplicate
    if ApplicableFee.first(:applicable_id => applicable_id, :applicable_type => applicable_type, :fee_id => fee_id,
                           :amount => amount, :applicable_on => applicable_on)
      return [false, "This seems like a duplicate fee"]
    else
      return true
    end
  end
end
