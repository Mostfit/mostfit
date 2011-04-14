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
end
