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
        staff_member_description = target.staff_member.name_and_id
        disbursed_till_date, disbursed_today = target.disbursements_till_date_and_today
        disb_variance_till_date, disb_variance_today = target.disbursements_variance

        payments_till_date, payments_today = target.payments_till_date_and_today
        payments_variance_till_date, payments_variance_today = target.payments_variance

        data[staff_member_description] = {
          :disbursements_target => target.disbursements_target,
          :disbursed_till_date => disbursed_till_date,
          :disbursements_variance_till_date => disb_variance_till_date,
          :approved_not_yet_disbursed => target.approved_not_yet_disbursed,
          :payments_till_date => payments_till_date,
          :payments_variance_till_date => payments_variance_till_date,
          :collections_target => target.collections_target
        }

        unless disbursed_today.nil?
          data[staff_member_description][:disbursed_today] = disbursed_today
          data[staff_member_description][:disbursements_variance_today] = disb_variance_today
        end
        unless payments_today.nil?
          data[staff_member_description][:payments_today] = payments_today
          data[staff_member_description][:payments_variance_today] = payments_variance_today
        end
      end
    end
    data
  end

end