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
    row_ids = repository.adapter.query(%Q{ # these are the loan history lines which represent the last line before @date
      SELECT CONCAT(loan_id,'_',max(date))
      FROM loan_history 
      WHERE date < '#{@date.strftime("%Y-%m-%d")}' and amount_in_default > 0
      GROUP BY loan_id})
    
    loans = Loan.all(:id => row_ids.map{|lid| lid.split("_")[0]})
    
    row_ids = "'" + row_ids.join("','") + "'"
    query = %Q{ # These are the lines from the loan history
      SELECT loan_id,branch_id, center_id, amount_in_default, days_overdue + DATEDIFF('#{@date.strftime("%Y-%m-%d")}', created_at) as late_by
      FROM loan_history 
      WHERE CONCAT(loan_id,'_',date) IN (#{row_ids})
      ORDER BY branch_id, center_id}
    pars = repository.adapter.query(query)
    par_map = pars.map{|p| [p.loan_id, p]}.to_hash
    debugger
                                    
    r = {}
    Branch.all.each do |b|
      r[b] = {}
      b.centers.each do |c|
        next if @center and not @center.find{|x| x.id==c.id}        
        r[b][c] = []
        loans.select{ |l| l.client.center == c}.each do |l|
          r[b][c] << [l, par_map[l.id]]
        end
      end
    end
    return r
  end
end
