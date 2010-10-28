class TransactionLedger < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def self.name
    "Transaction ledger"
  end

  def generate
    branches, centers, clients, groups, data = {}, {}, {}, {}, {}
    ClientGroup.all(:center => @center).each{|cg| groups[cg.id] = cg}
    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b

      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        data[b][c]||= {}
        centers[c.id]        = c
        c.clients.group_by{|x| x.client_group_id}.each{|cgid, client_grouped|
          cg = (cgid ? groups[cgid] : nil)
          data[b][c][cg] ||= []
          client_grouped.each{|client|
            data[b][c][cg] = {}
            clients[client.id] = client
          }
        }
      }
    }

    Payment.all(:received_on.gte => from_date, :received_on.lte => to_date, 
                :client_id => clients.keys).each{|p|
      #0          1,                 2                3
      #disbursed, payment_principal, payment_interest,payment_fee
      next if @loan_product_id and p.loan_id and p.loan.loan_product_id != @loan_product_id
      next unless client = clients[p.client_id]
      center = centers[client.center_id]
      branch = branches[center.branch_id]
      group  = groups[client.client_group_id]
      
      data[branch][center][group][p.received_on] ||= {}
      data[branch][center][group][p.received_on][client.name] ||= [0, 0, 0, 0]

      if p.type == :principal
        data[branch][center][group][p.received_on][client.name][1] += p.amount
      elsif p.type == :interest
        data[branch][center][group][p.received_on][client.name][2] += p.amount
      elsif p.type == :fees
        data[branch][center][group][p.received_on][client.name][3] += p.amount
      end
    }

    hash = {:disbursal_date.gte => from_date, :disbursal_date.lte => to_date, :rejected_on => nil}
    hash[:loan_product_id] = @loan_product_id if @loan_product_id
    Loan.all(hash).each{|loan|
      next unless client = clients[loan.client_id]
      center = centers[client.center_id]
      branch = branches[center.branch_id]
      group  = groups[client.client_group_id]

      data[branch][center][group][loan.disbursal_date] ||= {}
      data[branch][center][group][loan.disbursal_date][client.name] ||= [0, 0, 0, 0]
      data[branch][center][group][loan.disbursal_date][client.name][0] += loan.amount
    }
    return data
  end
end
