class AuditItem
  include DataMapper::Resource

  property :id, Serial

  property :audited_model, String
  property :audited_id, Integer
  property :due_on, Date
  property :created_at, DateTime
  property :status, Enum[:outstanding, :completed], :default => :outstanding
  property :result, Enum['',:pass, :fail], :default => '', :nullable => true

  belongs_to :assigned_to, :model => StaffMember

  validates_with_method :result, :result_needs_completed
  validates_with_method :object_exists
  def description
    "Audit of #{object.name} due by #{due_on}"
  end

  # It would be nice to validate audited_model before this gets called as trying to create
  # an audit_item without setting the model raises an error instead of a neat failed validation
  # Also instead of an ugly const_get maybe this could be replaced by a datamapper association?
  def object
    Kernel.const_get(audited_model).get(audited_id)
  end

  def result_needs_completed
    return [false, "Cannot set result unless audit is marked complete"] if result != "" and status != :completed
    return true
  end

  def object_exists
    return [false, "No #{audited_model} with id #{audited_id} exists"] unless object
    return true
  end

  # The AUDITABLES constant comes from config/constants.rb. Since this is the only place it
  # is used perhaps a local constant would be better? Or even just an array in this method?
  # Although perhaps it would be good to validate against in AuditTrail as well.
  def self.auditables
    AUDITABLES
  end

end
