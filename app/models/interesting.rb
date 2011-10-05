module Interesting
  
  DAILY = :daily; WEEKLY = :weekly; MONTHLY = :monthly; QUARTERLY = :quarterly; HALF_YEARLY = :half_yearly; YEARLY = :yearly
  FREQUENCIES = [ DAILY, WEEKLY, MONTHLY, QUARTERLY, HALF_YEARLY, YEARLY ]
  MULTIPLIERS = { DAILY => 365, WEEKLY => 52, MONTHLY => 12, QUARTERLY => 4, HALF_YEARLY => 2, YEARLY => 1 }
  
  ACTUAL_ACTUAL = :actual_actual; THIRTY_360 = :thirty_360; ACTUAL_365 = :actual_365; ACTUAL_360 = :actual_360
  DAY_COUNTS = [ ACTUAL_ACTUAL, THIRTY_360, ACTUAL_365, ACTUAL_360 ]
  DEFAULT_DAY_COUNT = ACTUAL_ACTUAL

  DEFAULT_MUST_ROUND = false

  def self.simple_interest_over_period(amount, nominal_interest_rate, from_date, to_date = Date.today, over_duration = YEARLY, using_day_count = DEFAULT_DAY_COUNT)
    adjusted_rate = duration_adjusted_rate(nominal_interest_rate, over_duration, from_date, to_date, using_day_count)
    amount * adjusted_rate
  end

  def self.duration_adjusted_rate(nominal_interest_rate, over_duration, from_date, to_date, using_day_count = DEFAULT_DAY_COUNT)
    raise ArgumentError, over_duration unless MULTIPLIERS.keys.include?(over_duration)
    nominal_interest_rate * MULTIPLIERS[over_duration] * factor(from_date, to_date, using_day_count)
  end

  def self.factor(from_date, to_date, day_count)
    raise ArgumentError, day_count unless DAY_COUNTS.include?(day_count)
    factor = 1
    case day_count
    when ACTUAL_ACTUAL then factor = (to_date - from_date + 1.0)/get_days_of_year(from_date, to_date)
    when ACTUAL_365 then factor = (to_date - from_date + 1.0)/365.0
    when ACTUAL_360 then factor = (to_date - from_date + 1.0)/360.0
    when THIRTY_360 then factor = (get_months(from_date, to_date) * 30.0)/360.0
    end
    factor
  end

  # currently just uses the civil year on the earlier date
  def self.get_days_of_year(from_date, to_date = nil)
    Date.leap?(from_date.year) ? 366 : 365
  end

  def self.get_months(from_date, to_date)
    return (to_date - from_date + 0.0)/number_of_days_in_month(to_date) if (from_date.year == to_date.year and from_date.mon == to_date.mon)
    pending_fraction_from_date = get_pending_fraction_of_month(from_date)
    elapsed_fraction_to_date = get_elapsed_fraction_of_month(to_date)
    fractions = pending_fraction_from_date + elapsed_fraction_to_date
    months_difference = (to_date.mon - from_date.mon).abs
    years_difference = to_date.year - from_date.year
    total_months = (to_date.mon > from_date.mon) ? (12 * years_difference) + months_difference : (12 * years_difference) - months_difference
    total_months + fractions - 1
  end

  def self.get_elapsed_fraction_of_month(on_date, must_round = DEFAULT_MUST_ROUND)
    elapsed = (on_date.day + 0.0)/number_of_days_in_month(on_date)
    must_round ? elapsed.round : elapsed
  end

  def self.get_pending_fraction_of_month(on_date, must_round = DEFAULT_MUST_ROUND)
    number_of_days = number_of_days_in_month(on_date)
    pending = (number_of_days - on_date.day + 0.0)/number_of_days
    must_round ? pending.round : pending
  end

  def self.first_of_next_month(for_date)
    raise ArgumentError, for_date unless (for_date and for_date.is_a?(Date))
    next_month_month, next_month_year = for_date.mon == 12 ? [1, for_date.year + 1] : [for_date.mon + 1, for_date.year]
    Date.new(next_month_year, next_month_month , 1)
  end

  def self.number_of_days_in_month(for_date)
    (first_of_next_month(for_date) - 1).day
  end

end
