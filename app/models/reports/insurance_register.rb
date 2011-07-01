class InsuranceRegister < Report
  attr_accessor :from_date, :to_date, :branch, :branch_id

  validates_with_method :branch_id, :branch_should_be_selected

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def self.name
    "Insurance Register"
  end

  def name
    "Insurance Register from #{@from_date} to #{@to_date}"
  end

  def generate
    r = repository.adapter.query(%Q{
                                    SELECT c.id as client_id, l.id as loan_id, c.reference, l.amount, c.name as client_name, c.gender as client_gender, c.date_of_birth as c_date_of_birth, c.occupation_id as c_occupation_id, l.disbursal_date, b.name as branch_name, o.name as occupation_name, g.id as guarantor_id, g.name as guarantor_name, g.date_of_birth as g_date_of_birth, g.gender as g_gender, g.guarantor_occupation_id as g_occupation_id   
                                    FROM clients c, loans l, guarantors g, branches b, occupations o 
                                    WHERE l.client_id = c.id AND g.client_id = c.id AND c.occupation_id = o.id AND g.guarantor_occupation_id = o.id AND l.c_branch_id = b.id AND l.occupation_id = o.id AND l.disbursal_date >= '#{from_date.strftime('%Y-%m-%d')}' AND l.disbursal_date <= '#{to_date.strftime('%Y-%m-%d')}' AND c.active = true AND b.id = #{@branch_id}
                                    ORDER by l.disbursal_date, c.id})
  end

  def branch_should_be_selected
    return [false, "Branch should be selected"] if branch_id.blank?
    return true
  end
end
