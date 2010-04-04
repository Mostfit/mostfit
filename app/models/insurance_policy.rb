class InsurancePolicy
  include DataMapper::Resource

  POLICY_STATUSES = [:active, :expired, :claim_pending, :claim_settled]
  
  property :id, Serial
  property :policy_no, String, :required => true
  property :sum_insured, Integer, :required => true
  property :premium, Integer, :required => true
  property :date_from, Date, :required => true
  property :date_to, Date, :required => true
  property :status, Enum.send("[]", *POLICY_STATUSES), :required => false

  belongs_to :insurance_company
  belongs_to :client

  validates_with_method :end_date_after_start_date

  def self.statuses
    POLICY_STATUSES
  end

  def description
    "#{insurance_company.name}: Rs.#{sum_insured}"
  end

  private

  def end_date_after_start_date
    return [false, "End date must be after start date"] unless date_to > date_from
    true
  end

end
