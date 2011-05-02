class MonthlyTarget
  include DataMapper::Resource

  property :id,                   Serial
  property :for_month,            Date, :nullable => false, :index => true
  property :staff_member_id,      Integer, :nullable => false, :index => true
  property :disbursements_target, Float
  property :collections_target,   Float

  belongs_to :staff_member

  before :create do
    throw :halt if MonthlyTarget.first(:for_month => for_month, :staff_member_id => staff_member_id)
  end

  validates_with_method :is_staff_member_active?

  def is_staff_member_active?
    staff_member.active ? true : [false, "Cannot set a target for an inactive staff member"]
  end

  def MonthlyTarget.get_first_date_of_month(month, year)
    if month && year
      return Date.new(year, month, 1)
    end
    nil
  end

  def MonthlyTarget.get_last_date_of_month(month, year)
    if month && year
      next_month, next_month_year = (month == 12) ? [1, year + 1] : [month + 1, year]
      first_of_next_month = get_first_date_of_month(next_month, next_month_year)
      return first_of_next_month - 1
    end
    nil
  end

  def to_s
    "Monthly Target for #{staff_member.name_and_id} for #{for_month.strftime("%B %Y")}"
  end

  def last_date_of_month
    for_month ? MonthlyTarget.get_last_date_of_month(for_month.mon, for_month.year) : nil
  end

  def disbursements_variance(on_date = Date.today)
    disbursed_till_date, disbursed_today = disbursements_till_date_and_today(on_date)
    [disbursements_target - disbursed_till_date, (disbursed_today.nil? ? nil : disbursements_target - disbursed_today)]
  end

  def disbursements_till_date_and_today(on_date = Date.today)
    on_date, previous_day = sanitize_date(on_date)
    [MonthlyTarget.disbursed_this_interval(for_month, on_date, staff_member_id),
      (previous_day ? MonthlyTarget.disbursed_this_interval(on_date, on_date, staff_member_id) : nil)]
  end

  def MonthlyTarget.disbursed_this_interval(from_date, to_date, staff)
    Loan.all(:disbursed_by_staff_id => staff, :scheduled_disbursal_date.lte => to_date,
      :disbursal_date.gte => from_date, :disbursal_date.lte => to_date, :approved_on.lte => to_date,
      :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i
  end
  
  def MonthlyTarget.collected_this_interval(from_date, to_date, staff)
    Payment.all(:received_on.gte => from_date, :received_on.lte => to_date, :received_by_staff_id => staff).aggregate(:amount.sum).to_i
  end

  def payments_variance(on_date = Date.today)
    payments_till_date, payments_today = payments_till_date_and_today(on_date)
    [collections_target - payments_till_date, (payments_today.nil? ? nil: collections_target - payments_today)]
  end

  def payments_till_date_and_today(on_date = Date.today)
    on_date, previous_day = sanitize_date(on_date)
    [MonthlyTarget.collected_this_interval(for_month, on_date, staff_member_id),
      (previous_day ? MonthlyTarget.collected_this_interval(on_date, on_date, staff_member_id) : nil)]
  end

  def approved_not_yet_disbursed(on_date = Date.today)
    on_date = sanitize_date(on_date)
    never_disbursed_total =  Loan.all(:approved_on.not => nil, :approved_by_staff_id => staff_member_id, :scheduled_disbursal_date.lte => on_date,
      :disbursal_date => nil, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i
    disbursed_later_total =  Loan.all(:approved_on.not => nil, :approved_by_staff_id => staff_member_id, :scheduled_disbursal_date.lte => on_date,
      :disbursal_date.gt => on_date, :rejected_on => nil, :written_off_on => nil).aggregate(:amount.sum).to_i
    never_disbursed_total + disbursed_later_total
  end

  def sanitize_date(given_date)
    given_date < last_date_of_month ? [given_date, given_date - 1] : [last_date_of_month, nil]
  end

end