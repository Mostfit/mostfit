class DailyTransactionSummary < Report
  attr_accessor :date, :branch, :branch_id
  
  DataRow = Struct.new(:disbursement, :collection, :foreclosure, :var_adjustment, :claim_settlement, :write_off)

  def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @name   = "Report for #{@date}"
    get_parameters(params, user)
  end
  
  def name
    "Daily transaction summary for #{@date}"
  end
  
  def self.name
    "Daily transaction summary"
  end
  
  def generate
    branches, data = {}, {}
    extra = []

    advances  = (LoanHistory.sum_advance_payment(self.date, self.date, [:branch], extra)||{}).group_by{|x| x.branch_id}
    balances  = (LoanHistory.advance_balance(self.date, :branch, extra)||{}).group_by{|x| x.branch_id}
    old_balances = (LoanHistory.advance_balance(self.date-1, :branch, extra)||{}).group_by{|x| x.branch_id}

    disbursements = (LoanHistory.sum_disbursed_grouped_by(:branch, @date, @date)||{}).map{|x| [x.branch_id, x.loan_amount]}.to_hash

    collections   = {:principal => {}, :interest => {}, :fees => {}}
    LoanHistory.sum_repayment_grouped_by(:branch, @date, @date).each{|type, branches|
      collections[type] = branches.map{|b| [b.branch_id, b.amount]}.to_hash
    }
    
    foreclosures  = LoanHistory.all(:status => :repaid,  :date => @date,
                                    :scheduled_outstanding_principal.gt => 0).aggregate(:branch_id, 
                                                                                        :principal_paid.sum, 
                                                                                        :interest_paid.sum).map{|x| [x[0], [x[1], x[2]]]}.to_hash
    write_offs    = LoanHistory.all(:status => :written_off,  :date => @date).aggregate(:branch_id, 
                                                                                        :actual_outstanding_principal.sum, 
                                                                                        :actual_outstanding_total.sum).map{|x| [x[0], [x[1], x[2]]]}.to_hash

    claimed       = LoanHistory.all(:status => :claim_settlement,  :date => @date).aggregate(:branch_id, 
                                                                                             :actual_outstanding_principal.sum, 
                                                                                             :actual_outstanding_total.sum).map{|x| [x[0], [x[1], x[2]]]}.to_hash

    #var_adjustments = old_balances - balances + advances
    @branch.each{|b|
      data[b]||= DataRow.new(0, {:principal => 0, :interest => 0, :fees => 0, :var => 0, :total => 0}, 
                             {:principal => 0, :interest => 0, :total => 0}, {:principal => 0, :interest => 0, :total => 0}, 
                             {:principal => 0, :interest => 0, :total => 0}, {:principal => 0, :interest => 0, :total => 0})
      
#       advance  = advances[c.id][0]        if advances.key?(b.id)
#       balance  = balances[c.id][0]        if balances.key?(b.id)
#       old_balance = old_balances[c.id][0] if old_balances.key?(b.id)
                
      data[b][0] += disbursements[b.id] || 0
      # collection
      data[b][1][:principal] += ((collections[:principal][b.id] || 0) - ( advances.key?(b.id) ? (advances[b.id][0][0] || 0) : 0 )) 
      data[b][1][:interest]  += ((collections[:interest][b.id] || 0) - 
                (( advances.key?(b.id) ? (advances[b.id][0][1] || 0) : 0 ) - ( advances.key?(b.id) ? (advances[b.id][0][0] || 0) : 0 ))) 
      data[b][1][:fees] += collections[:fees][b.id] || 0 
                
      branches[b.id] = b
      # client fee
      repository.adapter.query(%Q{
                               SELECT c.id center_id, c.branch_id branch_id, SUM(p.amount) amount
                               FROM  payments p, clients cl, centers c
                               WHERE p.received_on = '#{date.strftime('%Y-%m-%d')}' AND p.loan_id is NULL AND p.type=3
                               AND   p.deleted_at is NULL AND p.client_id=cl.id AND cl.center_id=c.id AND cl.deleted_at is NULL AND c.id in (#{@center.map{|c| c.id}.join(', ')})
                               GROUP BY branch_id, center_id
                             }).each{|p|
      if b == branches[p.branch_id]
        data[b][1][:fees] += p.amount.round(2)
      end
      }
 
      data[b][1][:total] += data[b][1][:principal] + data[b][1][:interest] + data[b][1][:fees]

      # foreclosure
      if foreclosures.key?(b.id)
        data[b][2][:principal] += foreclosures[b.id][0] || 0
        data[b][2][:interest]  += foreclosures[b.id][1] || 0
        data[b][2][:total]     += ((foreclosures[b.id][1] || 0) + (foreclosures[b.id][0] || 0))
      end

      # var adjusted
      if advances.key?(b.id)
        data[b][1][:var] += advances[b.id][0][1] || 0  
        data[b][1][:total] += (advances[b.id][0][1] || 0)    
        principal = ((advances[b.id][0][0] || 0) + 
                     (old_balances.key?(b.id) ? (old_balances[b.id][0][0] || 0) : 0) - 
                    (balances.key?(b.id) ? (balances[b.id][0][0] || 0) : 0 ))
        total = ((advances[b.id][0][1] || 0) + 
                 (old_balances.key?(b.id) ? (old_balances[b.id][0][1] || 0) : 0) - 
                (balances.key?(b.id) ? (balances[b.id][0][1] || 0) : 0 ))
        data[b][3][:principal] += principal
        data[b][3][:interest]  += (total - principal)
        data[b][3][:total] += total
      end

      # claimed or death settlement
       if claimed.key?(b.id)
        data[b][4][:principal] += claimed[b.id][0] || 0
        data[b][4][:interest]  += ((claimed[b.id][1] || 0) - (claimed[b.id][0] || 0))
        data[b][4][:total]     += claimed[b.id][1] || 0
      end
      
      # written off
      if write_offs.key?(b.id)
        data[b][5][:principal] += write_offs[b.id][0] || 0
        data[b][5][:interest]  += ((write_offs[b.id][1] || 0) - (write_offs[b.id][0] || 0))
        data[b][5][:total]     += write_offs[b.id][1] || 0
      end
    } 
    return data
  end
end
