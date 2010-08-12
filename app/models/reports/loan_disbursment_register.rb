class LoanDisbursementRegister < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today    
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
 end
  
  def name
    "Loan disbursement register from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Loan disbursment register"
  end
  
  def generate
    data, branches, centers, groups, loan_products = {}, {}, {}, {}, {}
    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        data[b][c]||= {}
        centers[c.id]        = c
        c.client_groups.sort_by{|x| x.name}.each{|g|
          groups[g.id] = g
          data[b][c][g] ||= []
        }
      }
    }
    #0      1           2           3               4             5                 6
    #ref_no,client_name,spouse_name,loan_product_id,loan_sequence,disbursement_date,amount
    #1: Applied on
    hash = {:disbursal_date.gte => from_date, :disbursal_date.lte => to_date}
    hash[:loan_product_id] = loan_product_id if loan_product_id
    Loan.all(hash).each{|l|
      client    = l.client
      center = centers[client.center_id]
      next unless center
      branch = branches[center.branch_id]
      data[branch][center][client.client_group] ||= []
      data[branch][center][client.client_group].push([client.reference, client.name, client.spouse_name, 
                                                      l.loan_product_id, l.cycle_number, l.disbursal_date, l.amount])
    }
    return data
  end

end
