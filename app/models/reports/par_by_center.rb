class ParByCenterReport < Report
  attr_accessor :date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id, :late_by_more_than_days, :late_by_less_than_days

  def initialize(params,dates, user)
    @date   = dates.blank? ? Date.today : dates[:date]
    @name   = "PAR Report as on #{@date}"
    @late_by_more_than_days = params[:late_by_more_than_days] if params and params.key?(:late_by_more_than_days) and not params[:late_by_more_than_days].blank?
    @late_by_less_than_days = params[:late_by_less_than_days] if params and params.key?(:late_by_less_than_days) and not params[:late_by_less_than_days].blank?
    get_parameters(params, user)
  end

  def name
    extra = []
    extra << "more than #{late_by_more_than_days} days" if late_by_more_than_days
    extra << "less than #{late_by_less_than_days} days" if late_by_less_than_days
    "PAR as on #{@date}: late by #{extra.join(' and ')}"
  end

  def self.name
    "PAR Report"
  end

  def include_late_day?(late_days)
    late_days > (late_by_more_than_days||0) and late_days < (late_by_less_than_days||INFINITY)
  end

  def generate
    debugger
    # these are the loan history lines which represent the last line before @date
    selects = [:loan_id, :branch_id, :center_id, :client_id, :amount_in_default, :days_overdue, :date]             
    par_data = LoanHistory.defaulted_loan_info_by(:center, @date, {:branch_id => @branch.map{|x| x.id}, :center_id => @center.map{|x| x.id}}, selects)

    center_defaults = {}
    clients = Client.all(:id => par_data.map{|x| x.client_id}, :fields => [:id, :name, :reference, :center_id]).map{|x| [x.id, x]}.to_hash
    hash    = {:client_id => clients.keys, :fields => [:id, :client_id, :loan_product_id, :amount]}
    hash[:loan_product_id] = loan_product_id if loan_product_id
    loans   = Loan.all(hash).map{|x| [x.id, x]}.to_hash
    center_defaults = par_data.group_by{|x| x.center_id}

    data = {}
    @branch.each do |branch|
      debugger
      data[branch] = {}
      @center.find_all{|c| c.branch_id==branch.id}.each do |center|
        debugger
        next unless center_defaults[center.id]
        data[branch][center] = []
        center_defaults[center.id].each do |default|
          next unless loans.key?(default.loan_id)
          loan = loans[default.loan_id]
          if default.date and @date > default.date - default.days_overdue
            late_by = default.days_overdue + (@date - default.date)
            next unless to_include = include_late_day?(late_by)
            data[branch][center] << [clients[default.client_id].name, clients[default.client_id].reference, loan.cycle_number, loan.loan_product.name, loan.amount, 
                                     loan.installment_frequency, default.pdiff, default.tdiff - default.pdiff, default.tdiff, late_by]
          end
        end
      end
    end
    return data
  end
end
