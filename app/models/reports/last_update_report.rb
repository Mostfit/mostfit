class LastUpdateReport < Report
  attr_accessor :branch, :branch_id 
  
  def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @name   = "Report for #{@date}"
    get_parameters(params, user)
  end
  
  def name
    "Last Update Report for #{@date}"
  end
  
  def self.name
    "Last Update Report"
  end
  
  def generate
    data = []
    if @branch_id and Branch.get(@branch_id).centers.empty?
      data = nil
    elsif @branch_id
      grouper = Branch.get(@branch_id).centers.aggregate(:id)
      d1 = Loan.all(:c_center_id => grouper).aggregate(:c_center_id, :c_last_payment_received_on.max, :created_at.max).group_by{|x| Center.get(x[0]).name}.to_hash
      d2 = Client.all(:center_id => grouper).aggregate(:center_id, :created_at.max).group_by{|x| Center.get(x[0]).name}.to_hash
    else
      grouper = Branch.all.aggregate(:id)
      d1 = Loan.all(:c_branch_id.not => nil).aggregate(:c_branch_id, :c_last_payment_received_on.max, :created_at.max).group_by{|x| Branch.get(x[0]).name}.to_hash
      d2 = []
      grouper.each{ |group|
        d2 << [group, Client.all('center.branch_id' => group).aggregate(:created_at.max)]
      }
      d2 = d2.group_by{|x| Branch.get(x[0]).name}.to_hash
      # data.each{ |datum|
      #   datum << Client.all('center.branch_id' => datum[0]).aggregate(:created_at.max)
      #   datum.unshift(Branch.get(datum[0]).name)
      # }
    end
    unless data == nil
      groups = d2.keys
      data = groups.map{|group| [group, d1[group], d2[group]]}
    end
    return data
  end
end 
