class ScheduledDisbursementRegister < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id

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
    branches, centers, groups, loans, loan_products = {}, {}, {}, {}, {}
    @branch.each{|b|
      loans[b.id]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        loans[b.id][c.id]||= {}
        centers[c.id]        = c
        c.client_groups.sort_by{|x| x.name}.each{|g|
          groups[g.id] = g
          loans[b.id][c.id][g.id] ||= []
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
      loan_products[l.loan_product_id] = l.loan_product if not loan_products.key?(l.loan_product_id)
      branch_id = centers[center_id].branch_id
      if not l.client.client_group_id
        loans[branch_id][center_id][0] ||= []
        groups[0]=ClientGroup.new(:name => "No group", :id => 0)
      end
      loans[branch_id][center_id][l.client.client_group_id||0].push([client.reference, client.name, client.spouse_name, 
                                                                     l.loan_product_id, l.cycle_number, l.scheduled_disbursal_date, l.amount])
    }
    return [groups, centers, branches, loans, loan_products]
  end
end
