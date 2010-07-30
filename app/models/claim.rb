class Claim
  include DataMapper::Resource
  after :save, :mark_client_loans
  
  before :valid?, :set_amount_to_be_paid_to_client
  before :valid?, :convert_blank_to_nil
  
  property :id, Serial
  property :date_of_death, Date, :nullable => false
  property :documents, Flag.send('[]', *CLAIM_DOCUMENTS)

  property :stop_further_installments, Boolean, :default => false
  property :refund_all_payments, Boolean, :default => false

  property :amount_of_claim, Float, :nullable => true, :min => 0
  property :amount_to_be_deducted, Float, :nullable => true, :min => 0
  property :amount_to_be_paid_to_client, Float, :nullable => true, :min => 0

  property :claim_submission_date, Date, :nullable => true
  property :receipt_of_claim_on, Date, :nullable => true
  property :payment_to_client_on, Date, :nullable => true

  property :claim_id,  String, :nullable => false  
  property :client_id, Integer, :nullable => false
  
  belongs_to :client
  
  validates_present :client
  validates_with_method :client, :client_marked_inactive
#  validates_with_method :payment_to_client_on, :payment_to_client_after_receipt
  validates_with_method :amount_to_be_paid_to_client, :payment_to_client_not_more_than_claim
  validates_with_method :amount_to_be_paid_to_client, :payment_to_be_deducted_not_more_than_claim
  validates_with_method :date_of_death, :date_of_death_cannot_be_in_future

  validates_with_method :date_of_death, :date_of_death_not_more_than_claim_submission
  validates_with_method :date_of_death, :date_of_death_not_more_than_receipt_of_claim_on
  validates_with_method :date_of_death, :date_of_death_not_more_than_client_payment
  validates_with_method :date_of_death, :date_of_death_not_before_date_of_joining

  def generate_claim_id
    self.claim_id = Date.today.strftime("%Y%m%d")
    if client
      self.claim_id += client.id.to_s
    end
    self.claim_id
  end

  def date_of_death_cannot_be_in_future
    if date_of_death and date_of_death.class==Date and date_of_death>Date.today
      return [false, "Date of death cannot be in future"]
    end
    return true
  end

  def client_marked_inactive
    if client and client.active
      return [false, "This client is active. A claim cannot be raised against an active client"]
    end
    return true
  end

  def date_of_death_not_before_date_of_joining
    if client and client.date_joined > date_of_death
      return [false, "Date of death cannot be before than date of joining of client"]
    end
    return true
  end
  
  def payment_to_client_after_receipt
    if payment_to_client_on and receipt_of_claim_on and payment_to_client_on < receipt_of_claim_on
      return [false, "Date of payment to client cannot be before receipt of payment to client"]
    else
      return true
    end
  end

  def payment_to_client_not_more_than_claim
    return [false, "Amount paid to client cannot be more than claim"] if amount_of_claim and amount_to_be_paid_to_client and amount_to_be_paid_to_client > amount_of_claim
    return true
  end

  def payment_to_be_deducted_not_more_than_claim
    return [false, "Amount deducted cannot be more than claim"] if amount_of_claim and amount_to_be_deducted and amount_to_be_deducted > amount_of_claim
    return true
  end

  def date_of_death_not_more_than_claim_submission
    if date_of_death.class==Date and claim_submission_date.class==Date and date_of_death > claim_submission_date
      return [false, "Date of submission of claim to insurance company cannot be before date of death"]
    else
      return true
    end
  end
  
  def date_of_death_not_more_than_receipt_of_claim_on
    if date_of_death.class==Date and receipt_of_claim_on.class==Date and date_of_death > receipt_of_claim_on
      return [false, "Date of claim receipt cannot be before date of death"]
    else
      return true
    end
  end

  def date_of_death_not_more_than_client_payment
    if date_of_death.class==Date and payment_to_client_on.class==Date and date_of_death > payment_to_client_on
      return [false, "Date of payment to client cannot be before date of death"]
    else
      return true
    end
  end

  def set_amount_to_be_paid_to_client
    if amount_of_claim and not amount_of_claim.blank? and amount_to_be_deducted and not amount_to_be_deducted.blank?
      self.amount_to_be_paid_to_client = amount_of_claim - amount_to_be_deducted
    else
      self.amount_to_be_paid_to_client = 0
    end
  end

  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and [Float, Integer].include?(self.class.send(k).type)
        self.send("#{k}=", nil)
      elsif v.is_a?(Mash) and [Date].include?(self.class.send(k).type)
        self.send("#{k}=", nil) if v[:month] and v[:month].blank? and v[:day] and v[:day].blank? and v[:year] and v[:year].blank?
      end
    }
  end

  def mark_client_loans
    self.client.check_client_deceased
  end
  
end
