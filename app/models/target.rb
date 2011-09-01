class Target
  include DataMapper::Resource
  TypeClasses = [Center, ClientGroup, Client, Loan, Loan]
  ValidAttaches = [:branch, :center, :staff_member]

  property :id,            Serial
  property :target_value,  Integer, :nullable => false, :index => true
  property :start_value,   Integer, :nullable => false, :index => true
  property :present_value, Integer, :nullable => true, :index => true

  property :target_of,     Enum.send('[]', *TargetOf), :nullable => false, :index => true
  property :target_type,   Enum.send('[]', *TargetType), :nullable => false, :index => true

  property :start_date,    Date, :nullable => true, :index => true
  property :deadline,      Date, :nullable => false, :index => true

  property :attached_to,   Enum.send('[]', *ValidAttaches), :nullable => false, :index => true
  property :attached_id,   Integer, :nullable => false, :index => true

  property :created_at,    DateTime, :default => Time.now
  property :checked_at,    Date

  validates_with_method :attached_id, :check_existance
  validates_with_method :deadline, :future_date
  validates_present :target_value
  validates_with_method :target_value, :target_value_invalid
  validates_present :start_date, :deadline
  validates_with_method :deadline, :start_date_cannot_be_greater_than_deadline

  before :valid?, :set_start_value

  def check_existance
    return true if responsible
    return [false, "This #{responsible_class} doesn't exists"]
  end

  def self.target_months
    MONTHS
  end

  def target_month_and_date_range_same
    return [false, "Target for Month cannot be different from month of date range specified"] if target_month.to_s.camelcase != start_date.strftime("%B") and target_month.to_s.camelcase!= deadline.strftime("%B")
    return true if target_month.to_s.camelcase == start_date.strftime("%B") and target_month.to_s.camelcase == deadline.strftime("%B")
  end

  def start_date_cannot_be_greater_than_deadline
    return [false, "Start date should be less than deadline"] if start_date and deadline and start_date > deadline
    return true
  end

  def target_value_invalid
    return [false, "This target value is not present"] if target_value.nil?
    return [false, "This target cannot be applied to this object"] if start_value.nil?
    return true if target_value > start_value
    return [false, "This target value of #{target_value} is less than present value of #{start_value}"] if target_value < start_value
    return [false, "This target value of #{target_value} is equal to present value of #{start_value}"] if target_value == start_value
  end

  def future_date
    return true if self.deadline and self.deadline>Date.today
    return [false, "Choose a future date"]
  end

  def responsible
    responsible_class.get(self.attached_id) if self.attached_to and self.attached_id
  end

  def responsible_class
    Kernel.const_get(self.attached_to.to_s.camelcase) if self.attached_to
  end

  def fetch_present_value
    klass  = TypeClasses[TargetOf.index(self.target_of)]
    method = klass.to_s.snake_case.pluralize.to_sym
    return unless self.attached_to and self.attached_id and self.target_of
    return unless responsible.respond_to?(method)
    count_method = "size"
    if self.target_of == :loan_disbursement_by_amount
      responsible.send(method).map{|x| x.amount}.reduce{|x, sum| sum+=x}
    else
      responsible.send(method).size
    end
  end

  def get_present_value
    if not checked_at or checked_at < Date.today
      self.present_value = fetch_present_value
      self.checked_at = Date.today
      self.save
    end
    self.present_value
  end

  def set_present_value
    self.present_value = fetch_present_value
  end

  def set_start_value    
    if self.new?
      if self.target_type == :relative
        self.start_value = fetch_present_value
      else
        self.start_value = 0
      end
    end
  end
end
