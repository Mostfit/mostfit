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
    on_date = sanitize_date(on_date)
    my_disbursed_loans = Loan.all(:disbursal_date.gte => for_month, :disbursal_date.lte => on_date, :disbursed_by_staff_id => staff_member_id)
    disbursed_this_month = my_disbursed_loans.inject(0.0) {|total_disbursed, loan| total_disbursed + loan.amount}
    disbursements_target - disbursed_this_month
  end

  def sanitize_date(given_date)
    given_date > last_date_of_month ? last_date_of_month : given_date
  end

end