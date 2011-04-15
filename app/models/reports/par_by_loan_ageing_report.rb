#This report shows the PAR values by Loan Ageing.
class ParByLoanAgeingReport < Report
  attr_accessor :date, :branch, :branch_id, :ageing_interval

  validates_with_method :date, :date_should_not_be_in_future

  validates_with_method :branch_id, :branch_should_be_selected

  validates_with_method :ageing_interval, :ageing_interval_must_be_selected


  def initialize(params, dates, user)
    @date = dates.blank? ? Date.today : dates[:date]
    @name = "PAR by Loan Ageing report as on #{@date}"
    get_parameters(params, user)
  end

  def name
    "PAR by Loan Ageing report as on #{@date} in #{@ageing_interval} intervals"
  end

  def self.name
    "Par by Loan Ageing report"
  end

  def generate
    data, ages = {}, {}

    @ageing_interval.times{|x|
      ages[x] = 0
    }
    
    @branch.each do |branch|
      data[branch] = {}
      branch.centers.managers.each{|manager|
        data[branch][manager] = 1.upto(@ageing_interval).map{|x| [x, 0]}.to_hash
        Loan.all(:fields => [:id, :disbursal_date, :client_id, :number_of_installments, :installment_frequency],
                 :disbursal_date.not => nil, :disbursal_date.lte => @date, "client.center.manager_staff_id" => manager.id).each{|l|
          age = (100 * (@date - l.disbursal_date) / (l.number_of_installments * l.installment_frequency_in_days) / @ageing_interval).ceil
          age = @ageing_interval if age > @ageing_interval
          data[branch][manager][age] += 1
        }
      }
    end
    return data
  end
  
  private
  def ageing_interval_must_be_selected
    return [false, "Ageing interval must be selected"] if @ageing_interval == nil or @ageing_interval == 0
    return true if @ageing_interval
  end
end
