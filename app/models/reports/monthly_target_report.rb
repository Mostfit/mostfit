class MonthlyTargetReport < Report
  attr_accessor :month, :chosen_year

  def initialize(params, dates, user)
    @month = (params && params[:month]) ? params[:month].to_i : Date.today.mon
    @chosen_year = (params && params[:chosen_year]) ? params[:chosen_year].to_i : Date.today.year
    get_parameters(params, user)
  end

  def name
    "Monthly Target Report"
  end

  def self.name
    "Monthly Target Report"
  end

  def generate
    data = {}
    begin_date = MonthlyTarget.get_first_date_of_month(@month, @chosen_year)
    if begin_date
      targets_for_month = MonthlyTarget.all(:for_month => begin_date)
      targets_for_month.each do |target|
        data[target.staff_member.name_and_id] = {
          :target => target,
          :disbursements_variance => target.disbursements_variance
        }
      end
    end
    data
  end

end