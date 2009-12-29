class TransactionLedger < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id

  def initialize(params, dates)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today

    @name     = "Report from #{@from_date.strftime("%d-%m-%Y")} to #{@to_date.strftime("%d-%m-%Y")}"

    @branch   = if params and params[:branch_id] and not params[:branch_id].blank?
                   Branch.all(:id => params[:branch_id])
                 else
                   Branch.all(:order => [:name])
                 end
    if params and params[:center_id] and not params[:center_id].blank? 
      @center = Center.all(:id => params[:center_id])
    elsif params and params[:staff_member_id] and not params[:staff_member_id].blank?
      @center = StaffMember.get(params[:staff_member_id]).centers
    else
      @center  = @branch.collect{|b| b.centers}.flatten
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
      client = p.loan_id ? p.loan.client : p.client
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

    Loan.all(:disbursal_date.gte => from_date, :disbursal_date.lte => to_date).each{|loan|
      payments[loan.disbursal_date]||={}
      payments[loan.disbursal_date][loan.client.client_group_id] ||= {}
      payments[loan.disbursal_date][loan.client.client_group_id][loan.client_id]||=[[], [], [], []]
      payments[loan.disbursal_date][loan.client.client_group_id][loan.client_id][0] << loan.amount
    }
    return [groups, centers, branches, payments, clients]
  end
end
