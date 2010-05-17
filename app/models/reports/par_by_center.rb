class ParByCenterReport < Report
  attr_accessor :date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id, :late_by_days

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
    # these are the loan history lines which represent the last line before @date
    rows = repository.adapter.query(%Q{
      SELECT loan_id,max(date)
      FROM loan_history 
      WHERE date < '#{@date.strftime("%Y-%m-%d")}' and amount_in_default > 0 and status in (5,6)
      GROUP BY loan_id})
    # These are the lines from the loan history
    query = %Q{
      SELECT loan_id, branch_id, center_id, client_id, amount_in_default, days_overdue as late_by, created_at,
             actual_outstanding_total-scheduled_outstanding_total total_due, actual_outstanding_principal-scheduled_outstanding_principal principal_due
      FROM loan_history 
      WHERE (loan_id,date) IN (#{rows.map{|x| "(#{x[0]}, '#{x[1].strftime("%Y-%m-%d")}')"}.join(',')})
      ORDER BY branch_id, center_id}
    center_defaults = {}
    par_data = repository.adapter.query(query)

    par_data.map{|p| 
      center_defaults[p.center_id] = [] if not center_defaults.key?(p.center_id)
      center_defaults[p.center_id] << p
    }
    clients = Client.all(:id => par_data.map{|x| x.client_id}, :fields => [:id, :name, :reference, :center_id]).map{|x| [x.id, x]}.to_hash
    hash    = {:client_id => clients.keys, :fields => [:id, :client_id, :loan_product_id, :amount]}
    hash[:loan_product_id] = loan_product_id if loan_product_id
    loans   = Loan.all(hash).map{|x| [x.id, x]}.to_hash
    r = {}
    @branch.each do |branch|
      r[branch] = {}
      @center.find_all{|c| c.branch_id==branch.id}.each do |center|
        next if not center_defaults[center.id]
        r[branch][center] = []
        center_defaults[center.id].each do |default|
          next if not loans.key?(default.loan_id)          
          loan = loans[default.loan_id]
          default.late_by
          if default.created_at and @date-default.created_at>0
            late_by = default.late_by + (@date-default.created_at.to_date).to_i
            next if late_by_days and late_by <= late_by_days
            r[branch][center] << [clients[default.client_id].name, clients[default.client_id].reference, loan.cycle_number, loan.loan_product.name, loan.amount, 
                                  loan.installment_frequency, default.principal_due, default.total_due-default.principal_due, default.total_due, late_by]
          end
        end
      end
    end
    return r
  end
end
