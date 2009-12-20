class TransactionLedger < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id

  def initialize(params, dates)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today

    @name     = "Report from #{@from_date.strftime("%d-%m-%Y")} to #{@to_date.strftime("%d-%m-%Y")}"
    @branch   = if params and params[:branch_id] and not params[:branch_id].nil?
                   Branch.all(:id => params[:branch_id])
                 else
                   Branch.all(:order => [:name])
                 end
    if params and params[:center_id] and not params[:center_id].blank? 
      @center = Center.all(:id => params[:center_id])
    else
      @center  = branch.centers
    end
  end 
  
  def generate
    branches, centers, groups, clients, payments = {}, {}, {}, {}, {}
    clients_grouped={}
    Client.all(:client_group_id.gt => 0).each{|client| 
      clients_grouped[client.client_group_id]||=[]
      clients_grouped[client.client_group_id].push(client)
    }
    @branch.each{|b|
      clients[b.id]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        next if @center and not @center.find{|x| x.id==c.id}
        clients[b.id][c.id]||= {}
        centers[c.id]        = c
        c.client_groups.each{|g|
          groups[g.id] = g
          clients[b.id][c.id][g.id] ||= []
          clients_grouped[g.id].each{|client|
            clients[b.id][c.id][g.id].push(client)
            payments[client.id]||={}
          }
        }
      }
    }
    
    Payment.all(:received_on.gte => from_date, :received_on.lte => to_date).each{|p| 
      #0          1,                 2                3
      #disbursed, payment_principal, payment_interest,payment_fee      
      client = p.loan.client
      next if not payments[client.id]
      payments[client.id][p.received_on] = [0, 0, 0, 0] if not payments[client.id][p.received_on]
      if p.type == :principal
        payments[client.id][p.received_on][1] += p.amount
      elsif p.type == :interest
        payments[client.id][p.received_on][2] += p.amount
      elsif p.type == :fees
        payments[client.id][p.received_on][3] += p.amount
      end
    }
    Loan.all(:disbursal_date.gte => from_date, :disbursal_date.lte => to_date).each{|loan|
      next if not payments[loan.client_id]
      payments[loan.client_id][loan.disbursal_date] = [0, 0, 0, 0] if not payments[loan.client_id][loan.disbursal_date]
      payments[loan.client_id][loan.disbursal_date][0] = loan.amount
    }
    return [groups, centers, branches, payments, clients]
  end
end
