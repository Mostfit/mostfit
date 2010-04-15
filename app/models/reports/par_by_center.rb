class ParByCenterReport < Report
  attr_accessor :date, :branch, :center, :branch_id, :center_id, :staff_member_id

  def initialize(params,dates, user)
    @date = dates.blank? ? Date.today : dates[:date]
    @name   = "PAR Report as on #{@date}"
    get_parameters(params, user)
  end

  def name
    "PAR as on #{@date}"
  end

  def self.name
    "PAR Report"
  end

  def generate
    debugger
    loan_ids = repository.adapter.query(%Q{
      SELECT CONCAT(loan_id,'_',max(date))
      FROM loan_history 
      WHERE date < '#{@date.strftime("%Y-%m-%d")}' and amount_in_default > 0
      GROUP BY loan_id})
    # these are the loan history lines which represent the last line before @date
    loan_ids = "'" + loan_ids.join("','") + "'"
    pars = repository.adapter.query(%Q{
      SELECT branch_id, center_id, amount_in_default, days_overdue + DATEDIFF(#{@date.strftime("%Y-%m-%d")}, created_at) as late_by
      FROM loan_history 
      WHERE CONCAT(loan_id,'_',date) IN (#{loan_ids})
      ORDER BY branch_id, center_id})
                                    
    r = {}
    loans = Loan.all(:id => loan_ids.map{|lid| lid.split("_")[0]})
    pars.each do |p|
      if r.has_key?(p.branch_id)
        if r[p.branch_id].has_key?(p.center_id)
          r[p.branch_id][p.center_id] << p
        else
          r[p.branch_id][p.center_id] = [p]
        end
      else
        r[p.branch_id] = {p.center_id => [p]}
      end
    end
    debugger
    return r
  end
end
