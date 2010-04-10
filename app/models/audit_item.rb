class AuditItem
  include DataMapper::Resource

  AUDITABLES = ["Branch","Center","Group","Client","Loan","Payment","StaffMember"]

  property :id, Serial

  property :audited_model, String
  property :audited_id, Integer
  property :due_on, Date
  property :created_at, DateTime
  property :status, Enum[:outstanding, :completed], :default => :outstanding
  property :result, Enum['',:pass, :fail], :default => '', :nullable => true


  belongs_to :assigned_to, :model => StaffMember

  validates_with_method :result, :result_needs_completed
  def description
    "Audit of #{object.name} due by #{due_on}"
  end

  def object
    Kernel.const_get(audited_model).get(audited_id)
  end

  def result_needs_completed
    return [false, "Cannot set result unless audit is marked complete"] if result != "" and status != :completed
    return true
  end
  
  def self.auditables
    AUDITABLES
  end

end
