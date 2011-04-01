require 'weeksheet_element'

class WeeksheetRow
  include DataMapper::Resource
  
  property :id,         Serial
  property :on_date,    Date
  property :center_id,	Integer
  property :client_id,	Integer
  property :loan_id,    Integer
  property :balance,    Float
  property :installment, Integer
  property :principal,  Float
  property :interest,   Float
  property :fees,       Float
  property :received_now, Float, :default => 0.0
  property :attendance, DataMapper::Property::Enum.send('[]', *ATTENDANCE)
  property :received_was_edited,  Boolean, :default => false
  property :attendance_was_edited,  Boolean, :default => false

  belongs_to :center
  belongs_to :client
  belongs_to :loan
  belongs_to :weeksheet

  has n, :payments
  has 1, :attendance_record, :model => 'Attendance'

  def disbursed_amount
    loan ? loan.amount : "N.A."
  end

  def get_value(element)
    case element
    when Client_element then client
    #when Group_element then group
    when Loan_element then loan
    when Disbursed_element then disbursed_amount
    when Balance_element then balance
    when Installment_element then installment
    when Principal_element then principal
    when Interest_element then interest
    when Fees_element then fees
    when Expected_element then display_expected
    when Received_now_element then received_now
    when Received_earlier_element then already_received
    when Date_element then on_date
    when Attendance_element then display_attendance
    else nil
    end
  end

  def display_expected
    original_expected = principal + interest + fees
    new_expected = original_expected - already_received
    new_expected == original_expected ? "#{original_expected}" : "#{new_expected} (#{original_expected})"
  end

  def already_received
    recorded_receipts = 0.0
    payments.each do |payment|
      recorded_receipts += payment.amount
    end
    recorded_receipts
  end

  def display_attendance
    attendance
  end
  
  def set_value(value, element)
    if element == Received_now_element
      set_received(value)
    elsif element == Attendance_element
      set_attendance(value)
    end
    save
  end

  def set_received(value)
    @received_now = Float value
    @received_was_edited = true
  end

  def set_attendance(attended)
    @attendance = :Late
    @attendance_was_edited = true
  end

  def save_edits
    #ftw: dirty? and attribute_dirty? don't seem to work from datamapper
    not_dirty = (!attendance_was_edited) && (!received_was_edited)
    return if not_dirty
    update_attendance_record
    update_payments
    save
    #Reset edited flags
    @attendance_was_edited = @received_was_edited = false
    save
  end

  def update_attendance_record
    if (attendance_was_edited)
      if (@attendance_record)
        @attendance_record.update(:date => on_date, :status => attendance)
      else
        @attendance_record = Attendance.new(:client => client, :center => center, :date => on_date, :status => attendance)
      end
    end
  end

  def update_payments
    if (received_now > 0 && received_was_edited)
      @payments << new_payment(received_now)
    end
  end
  
  def new_payment(for_amount)
    Payment.new(:amount => for_amount, :received_on => on_date, :created_at => Time.now, :received_by_staff_id => center.manager_staff_id, :loan => loan, :client => client)
  end

  def set_received_in_full
    set_received(net_receivable)
  end

  def net_receivable
    (principal + interest + fees) - already_received
  end

  def to_s
    "#{id} with expected: #{net_receivable} and already received: #{already_received}"
  end

end