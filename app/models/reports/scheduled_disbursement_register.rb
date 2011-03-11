class ScheduledDisbursementRegister < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id

  validates_with_method :branch_id, :branch_should_be_selected

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today    
    @name      = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
 end
  
  def name
    "Loan scheduled disbursement register from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Loan scheduled disbursment register"
  end
  
  def generate
    branches, centers, groups, data = {}, {}, {}, {}
    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        data[b][c]||= {}
        centers[c.id]        = c
        c.client_groups.each{|g|
          groups[g.id] = g
          data[b][c][g] ||= []
        }
      }
    }
    #0      1           2           3               4             5                 6
    #ref_no,client_name,spouse_name,loan_product_id,loan_sequence,disbursement_date,amount
    #1: Applied on
    hash = {:scheduled_disbursal_date.gte => from_date, :scheduled_disbursal_date.lte => to_date, :disbursal_date => nil, :approved_on.not => nil, :rejected_on => nil}
    hash[:loan_product_id] = loan_product_id if loan_product_id
    Loan.all(hash).each{|l|
      client    = l.client
      center_id = client.center_id      
      next if not centers.key?(center_id)
      center    = centers[center_id]
      branch    = branches[center.branch_id]
      group     = l.client.client_group
      data[branch][center][group]||=[]
      data[branch][center][group].push([client.reference, client.name, client.spouse_name, 
                                        l.loan_product_id, l.cycle_number, l.scheduled_disbursal_date, l.amount])
    }
    return data
  end
end
