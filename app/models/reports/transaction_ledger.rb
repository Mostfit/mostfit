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
    branches, centers, groups, clients, payments = {}, {}, {}, {}, {}
    clients_grouped, clients_ungrouped = {}, {}
    Client.all(:fields => [:id, :client_group_id, :center_id, :name], :client_group_id.gt => 0).each{|client|
      clients_grouped[client.client_group_id]||=[]
      clients_grouped[client.client_group_id].push(client)
      clients_ungrouped[client.id]=client
    }
    @branch.each{|b|
      clients[b.id]||= {}
      branches[b.id] = b

      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        clients[b.id][c.id]||= {}
        centers[c.id]        = c
        c.client_groups.sort_by{|x| x.name}.each{|g|
          groups[g.id] = g
          clients[b.id][c.id][g.id] ||= []
          clients_grouped[g.id].each{|client|
            clients[b.id][c.id][g.id].push(client)
          } if clients_grouped[g.id]
        }
      }
    }

    Payment.all(:received_on.gte => from_date, :received_on.lte => to_date).each{|p|
      #0          1,                 2                3
      #disbursed, payment_principal, payment_interest,payment_fee
      next if @loan_product_id and p.loan_id and p.loan.loan_product_id!=@loan_product_id
      client = p.client_id ? clients_ungrouped[p.client_id] : p.loan.client(:fields => [:id, :client_group_id])
      next if not client
      payments[p.received_on]||={}
      payments[p.received_on][client.client_group_id]||={}
      payments[p.received_on][client.client_group_id][client.id]||=[[], [], [], []]

      next if not payments[p.received_on][client.client_group_id][client.id]

      if p.type == :principal
        payments[p.received_on][client.client_group_id][client.id][1] << p.amount
      elsif p.type == :interest
        payments[p.received_on][client.client_group_id][client.id][2] << p.amount
      elsif p.type == :fees
        payments[p.received_on][client.client_group_id][client.id][3] << p.amount
      end
    }
    hash = {:disbursal_date.gte => from_date, :disbursal_date.lte => to_date}
    hash[:loan_product_id] = @loan_product_id if @loan_product_id
    Loan.all(hash).each{|loan|
      client = clients_ungrouped[loan.client_id]
      next if not client
      payments[loan.disbursal_date]||={}
      payments[loan.disbursal_date][client.client_group_id] ||= {}
      payments[loan.disbursal_date][client.client_group_id][client.id]||=[[], [], [], []]
      payments[loan.disbursal_date][client.client_group_id][client.id][0] << loan.amount
    }
    return [groups, centers, branches, payments, clients]
  end
end
