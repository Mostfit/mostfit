class ConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :branch_id, :center_id

  def initialize(from_date=Date.today-7, to_date=Date.today)
    @from_date   =  (from_date.class==Date) ? from_date : Date.parse(from_date)
    @to_date     =  (to_date.class==Date) ?   to_date : Date.parse(to_date)
    @name        = "Report from #{@from_date.strftime("%d-%m-%Y")} to #{@to_date.strftime("%d-%m-%Y")}"
  end
  
  def name
    "Report from #{@from_date.strftime("%d-%m-%Y")} to #{@to_date.strftime("%d-%m-%Y")}"
  end
  
  def generate(params)
    branches, centers, groups = {}, {}, {}
    histories = LoanHistory.sum_outstanding_by_group(self.from_date, self.to_date)
    ((params and params[:branch_id] and not params[:branch_id].blank?) ? Branch.all(:id => params[:branch_id]) : Branch.all(:order => [:name])).each{|b|      
      groups[b.id]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        next if params[:center_id] and not params[:center_id].blank? and not params[:center_id].to_i==c.id
        groups[b.id][c.id]||= {}
        centers[c.id]  = c
        c.client_groups.each{|g|
          #0              1                 2                3              4              5     6                  7         8    9,10,11     12         13
          #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults, name
          groups[b.id][c.id][g.id] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, g.name]
          history  = histories.find{|x| x.client_group_id==g.id and x.center_id==c.id}
          if history
            principal_scheduled = history.scheduled_outstanding_principal.to_i
            total_scheduled     = history.scheduled_outstanding_total.to_i

            principal_actual = history.actual_outstanding_principal.to_i
            total_actual     = history.actual_outstanding_total.to_i            
          else
            principal_scheduled, total_scheduled, principal_actual, total_actual = 0, 0, 0, 0
          end

          groups[b.id][c.id][g.id][6] += principal_actual
          groups[b.id][c.id][g.id][8] += total_actual
          groups[b.id][c.id][g.id][7] += total_actual - principal_actual

          groups[b.id][c.id][g.id][9]  += principal_scheduled - principal_actual
          groups[b.id][c.id][g.id][10] += (total_scheduled - total_actual) - (principal_scheduled - principal_actual)
          groups[b.id][c.id][g.id][11] += total_scheduled - total_actual 
        }
      }
    }
    Payment.all(:received_on.gte => from_date, :received_on.lte => to_date ).each{|p|
      client    = p.loan.client
      center_id = client.center_id
      next if not centers.key?(center_id)
      branch_id = centers[center_id].branch_id

      groups[branch_id][center_id][client.client_group_id][3] += p.amount if p.type==:principal
      groups[branch_id][center_id][client.client_group_id][4] += p.amount if p.type==:interest
      groups[branch_id][center_id][client.client_group_id][5] += p.amount if p.type==:fees
    }
    #1: Applied on
    Loan.all(:applied_on.gte => from_date, :applied_on.lte => to_date).each{|l|
      client    = l.client
      center_id = client.center_id
      next if not centers.key?(center_id)
      branch_id = centers[center_id].branch_id

      groups[branch_id][center_id][l.client.client_group_id][0] += l.amount
    }

    #2: Approved on
    Loan.all(:approved_on.gte => from_date, :approved_on.lte => to_date).each{|l|
      client    = l.client
      center_id = client.center_id
      next if not centers.key?(center_id)
      branch_id = centers[center_id].branch_id

      groups[branch_id][center_id][l.client.client_group_id][1] += l.amount
    }

    #3: Disbursal date
    Loan.all(:disbursal_date.gte => from_date, :disbursal_date.lte => to_date).each{|l|
      client    = l.client
      center_id = client.center_id
      next if not centers.key?(center_id)
      branch_id = centers[center_id].branch_id

      groups[branch_id][center_id][l.client.client_group_id][2] += l.amount
    }
    return [groups, centers, branches]
  end
end
