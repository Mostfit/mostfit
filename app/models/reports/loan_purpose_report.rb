class LoanPurposeReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.min_date
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today  
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end
  
  def name
    "Loan Purpose Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Loan purpose report"
  end
  
  def generate
    branches, centers, data, purposes, clients = {}, {}, {}, {}, {}
    histories = LoanHistory.sum_outstanding_grouped_by(to_date, ["occupation", "branch"], loan_product_id).group_by{|x| x.branch_id}
  
    Occupation.all.each{|p| purposes[p.id]=p}
    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      next unless histories.key?(b.id)
      histories[b.id].each{|history|
        purpose = purposes[history.occupation_id]
        #0              1                 2                3              4              5     6                  7         8    9,10,11     12         13
        #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults, name
        data[b][purpose] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]        
        principal_scheduled = history.scheduled_outstanding_principal
        total_scheduled     = history.scheduled_outstanding_total
        
        principal_actual    = history.actual_outstanding_principal
        total_actual        = history.actual_outstanding_total
        
        principal_advance   = history.advance_principal
        total_advance       = history.advance_total
        
        data[b][purpose][7] += principal_actual
        data[b][purpose][9] += total_actual
        data[b][purpose][8] += total_actual - principal_actual
        
        data[b][purpose][10]  += (principal_actual > principal_scheduled ? principal_actual-principal_scheduled : 0)
        data[b][purpose][11] += ((total_actual-principal_actual) > (total_scheduled-principal_scheduled) ? (total_actual-principal_actual - (total_scheduled-principal_scheduled)) : 0)
        data[b][purpose][12] += total_actual > total_scheduled ? total_actual - total_scheduled : 0
        
        data[b][purpose][13]  += principal_advance
        data[b][purpose][15] += total_advance
        data[b][purpose][14] += (total_advance - principal_advance)
      }
    }

    payments = repository.adapter.query(%Q{
                               SELECT l.occupation_id as occupation_id, c.branch_id branch_id, p.type ptype, SUM(p.amount) amount
                               FROM clients cl, loans l, centers c, payments p
                               WHERE p.received_on >= '#{from_date.strftime('%Y-%m-%d')}' and p.received_on <= '#{to_date.strftime('%Y-%m-%d')}'
                               AND p.deleted_at is NULL AND p.loan_id=l.id AND l.client_id=cl.id AND cl.center_id=c.id 
                               AND cl.deleted_at is NULL AND c.branch_id in (#{branches.keys.join(',')})
                               GROUP BY l.occupation_id, c.branch_id, p.type
                             }).group_by{|x| x.branch_id}
    payments.each{|branch_id, loan_purposes| 
      if branch = branches[branch_id]
        loan_purposes.group_by{|x| x.occupation_id}.each{|purpose_id, payments|
          purpose = purposes[purpose_id]
          data[branch][purpose] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          payments.each{|p|
            if p.ptype==1
              data[branch][purpose][3] += p.amount.round(2)
            elsif p.ptype==2
              data[branch][purpose][4] += p.amount.round(2)
            elsif p.ptype==3
              data[branch][purpose][5] += p.amount.round(2)
            end
            data[branch][purpose][6] += p.amount.round(2)
          } 
        }
      end
    }
      
    #1: Applied on
    hash = {:applied_on.gte => from_date, :applied_on.lte => to_date}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    group_loans(["l.occupation_id", "c.branch_id"], "sum(if(amount_applied_for>0, amount_applied_for, amount)) amount", hash).group_by{|x| x.branch_id}.each{|branch_id, loan_purposes|
      next unless branches.key?(branch_id)
      branch  = branches[branch_id]
      loan_purposes.group_by{|x| x.occupation_id}.each{|purpose_id, loans|
        purpose = purposes[purpose_id]        
        data[branch][purpose] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        l = loans.first
        data[branch][purpose][0] += l.amount if loans.length>0
      }
    }
    
    #2: Approved on
    hash = {:approved_on.gte => from_date, :approved_on.lte => to_date, :rejected_on => nil}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    group_loans(["l.occupation_id", "c.branch_id"], "sum(if(amount_sanctioned>0, amount_sanctioned, amount)) amount", hash).group_by{|x| x.branch_id}.each{|branch_id, loan_purposes|
      next unless branches.key?(branch_id)
      branch  = branches[branch_id]
      loan_purposes.group_by{|x| x.occupation_id}.each{|purpose_id, loans|
        purpose = purposes[purpose_id]        
        data[branch][purpose] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        l = loans.first
        data[branch][purpose][1] += l.amount if loans.length>0
      }
    }
    #3: Disbursal date
    hash = {:disbursal_date.gte => from_date, :disbursal_date.lte => to_date, :rejected_on => nil}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    group_loans(["l.occupation_id", "c.branch_id"], "sum(amount) amount", hash).group_by{|x| x.branch_id}.each{|branch_id, loan_purposes|
      next unless branches.key?(branch_id)
      branch  = branches[branch_id]
      loan_purposes.group_by{|x| x.occupation_id}.each{|purpose_id, loans|
        purpose = purposes[purpose_id]        
        data[branch][purpose] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        data[branch][purpose][2] += loans.first.amount if loans.length>0
      }
    }
    return data
  end
end
