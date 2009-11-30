class DailyReport < Report
  attr_accessor :date

  def initialize(date=Date.today)
    @date   =  (date.class==Date) ? date : Date.parse(date)
    @name   = "Report for #{@date.strftime("%d-%m-%Y")}"
  end
  
  def name
    "Report for #{date.strftime("%d-%m-%Y")}"
  end
  
  def generate(params)
    branches, centers, groups = {}, {}, {}
    (params[:branch_id].nil? ? Branch.all(:order => [:name]) : Branch.all(params[:branch_id])).each{|b|
      groups[b.id]||= {}
      branches[b.id] = b
      b.centers.each{|c|
        groups[b.id][c.id]||= {}
        centers[c.id]  = c
        c.client_groups.each{|g|
          #0              1                 2                3                  4                   5                   6               7               8
          #amount_applied,amount_sanctioned,amount_disbursed,principal_paidback,balance_outstanding,interest_collected, processing_fee, no_of_defaults, name
          groups[b.id][c.id][g.id] = [0, 0, 0, 0, 0, 0, 0, 0, g.name]
          loan_ids = g.clients.loans.collect{|x| x.id}
          groups[b.id][c.id][g.id][3] += if loan_ids.length > 0
                                           LoanHistory.sum_outstanding_for(self.date, loan_ids)[0].scheduled_outstanding_total.to_i
                                         else
                                           0
                                         end
        }
      }
    }

    Payment.all(:received_on => date).each{|p|
      client    = p.loan.client
      center_id = client.center_id
      branch_id = centers[center_id].branch_id

      groups[branch_id][center_id][client.client_group_id][4] += p.amount if p.type==:principal
      groups[branch_id][center_id][client.client_group_id][5] += p.amount if p.type==:interest
      groups[branch_id][center_id][client.client_group_id][6] += p.amount if p.type==:fee
    }
    #1: Applied on
    Loan.all(:applied_on => date).each{|l|
      client    = l.client
      center_id = client.center_id
      branch_id = centers[center_id].branch_id

      groups[branch_id][center_id][l.client.client_group_id][0] = l.amount
    }

    #2: Approved on
    Loan.all(:approved_on => date).each{|l|
      client    = l.client
      center_id = client.center_id
      branch_id = centers[center_id].branch_id

      groups[branch_id][center_id][l.client.client_group_id][1] = l.amount
    }

    #3: Disbursal date
    Loan.all(:disbursal_date => date).each{|l|
      client    = l.client
      center_id = client.center_id
      branch_id = centers[center_id].branch_id

      groups[branch_id][center_id][l.client.client_group_id][2] = l.amount
    }
    return [groups, centers, branches]
  end
end
