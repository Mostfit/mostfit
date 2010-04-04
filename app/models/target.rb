class Target
  include DataMapper::Resource
  Types = [:center_creation, :group_creation, :client_registration, :loan_disbursement_by_amount, :loan_disbursements_by_number]
  TypeClasses = [Center, ClientGroup, Client, Loan, Loan]
  ValidAttaches = [:branch, :center, :staff_member]

  property :id,            Serial
  property :target_value,  Integer, :nullable => false, :index => true
  property :start_value,   Integer, :nullable => false, :index => true
  property :type,          Enum.send('[]', *Types), :nullable => false, :index => true
  property :deadline,      Date, :nullable => false, :index => true
  property :attached_to,   Enum.send('[]', *ValidAttaches), :nullable => false, :index => true
  property :attached_id,   Integer, :nullable => false, :index => true
  property :created_at,    DateTime, :default => Time.now
  property :present_value, Integer, :nullable => true, :index => true
  property :checked_at,    Date

  validates_with_method :attached_id, :check_existance
  validates_with_method :deadline, :future_date
  validates_present :target_value
  validates_with_method :target_value, :target_value_invalid

  before :valid?, :set_start_value

  def check_existance
    return true if responsible
    return [false, "This #{responsible_class} doesn't exists"]
  end

  def target_value_invalid
    return [false, "This target value is not present"] if target_value.nil?
    return [false, "This target cannot be applied to this object"] if start_value.nil?
    return true if target_value > start_value
    return [false, "This target value of #{target_value} is less than present value of #{start_value}"] if target_value < start_value
    return [false, "This target value of #{target_value} is equal to present value of #{start_value}"] if target_value == start_value
  end

  def future_date
    return true if self.deadline>Date.today
    return [false, "Choose a future date"]
  end

  def responsible
    responsible_class.get(self.attached_id)
  end

  def responsible_class
    Kernel.const_get(self.attached_to.to_s.camelcase)
  end

  def fetch_present_value
    klass  = TypeClasses[Types.index(self.type)]
    method = klass.to_s.snake_case.pluralize.to_sym
    return unless self.attached_to and self.attached_id and self.type
    return unless responsible.respond_to?(method)
    count_method = "size"
    if self.type==:loan_disbursement_by_amount
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
    self.start_value = fetch_present_value if self.new?
  end
end
