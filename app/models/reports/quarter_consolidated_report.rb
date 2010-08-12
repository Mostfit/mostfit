class QuarterConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :branch, :branch_id, :loan_product_id
  QUARTERS = {1 => [:april, :may, :june], 2 => [:july, :august, :september], 3 => [:october, :november, :december], 4 => [:january, :february, :march]}
  MONTHS  = [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.min_date
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.new(Date.today.year, Date.today.month-1, -1)
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end
  
  def name
    "Quarter wise Consolidated Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Quarter wise Consolidated report"
  end
  
  def generate
    data = {}
    this_year = Date.today.year
    this_month = Date.today.month
#    histories = LoanHistory.sum_outstanding_by_month(self.from_date, self.to_date, self.loan_product_id)
    @branch.each{|branch|
      data[branch]||= {}
      (branch.creation_date.year..this_year).each{|year|
        QUARTERS.each{|q, months|
          months.each{|month|
            month_number = MONTHS.index(month) + 1
            quarter = get_quarter(month_number)
            y = (quarter==4 ? year+1 : year)
            # we do not generate report for the ongoing month
            next if year>=this_year and month_number >= this_month
            next if Date.today < Date.new(y, month_number, 1)
            histories = LoanHistory.sum_outstanding_by_month(month_number, y, branch, self.loan_product_id)
            next if not histories
            data[branch][year]||= {}
            data[branch][year][quarter]||= {}
            
            #0        1          2                3              4          5     6                  7       8    9,10,11     12,13,14   15
            #applied, sanctioned,disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults, name      
            data[branch][year][quarter][month] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

            if histories and history = histories.first
              principal_scheduled = history.scheduled_outstanding_principal
              total_scheduled     = history.scheduled_outstanding_total
              
              principal_actual    = history.actual_outstanding_principal
              total_actual        = history.actual_outstanding_total
              
              principal_advance   = history.advance_principal
              total_advance       = history.advance_total
            else
              principal_scheduled, total_scheduled, principal_actual, total_actual, principal_advance, total_advance = 0, 0, 0, 0, 0, 0
            end
            
            data[branch][year][quarter][month][7] += principal_actual
            data[branch][year][quarter][month][9] += total_actual
            data[branch][year][quarter][month][8] += total_actual - principal_actual
          
            data[branch][year][quarter][month][10]  += (principal_actual > principal_scheduled ? principal_actual-principal_scheduled : 0)
            data[branch][year][quarter][month][11] += ((total_actual-principal_actual) > (total_scheduled-principal_scheduled) ? (total_actual-principal_actual - (total_scheduled-principal_scheduled)) : 0)
            data[branch][year][quarter][month][12] += total_actual > total_scheduled ? total_actual - total_scheduled : 0
            
            data[branch][year][quarter][month][13]  += principal_advance
            data[branch][year][quarter][month][15] += total_advance
            data[branch][year][quarter][month][14] += (total_advance - principal_advance)
          }
        }
      }
    }
    branch_ids  = @branch.length>0 ? @branch.map{|x| x.id}.join(",") : "NULL"
    # payments
    extra_condition = ""
    froms = "payments p, clients cl, centers c"
    if self.loan_product_id
      froms+= ", loans l"
      extra_condition = " and p.loan_id=l.id and l.loan_product_id=#{self.loan_product_id}"
    end

    repository.adapter.query(%Q{
                               SELECT c.branch_id branch_id, year(received_on) year, month(received_on) month, p.type ptype, SUM(p.amount) amount
                               FROM #{froms}
                               WHERE p.received_on >= '#{from_date.strftime('%Y-%m-%d')}' and p.received_on <= '#{to_date.strftime('%Y-%m-%d')}'
                               AND p.deleted_at is NULL AND p.client_id = cl.id AND cl.center_id=c.id AND c.branch_id in (#{branch_ids}) #{extra_condition}
                               GROUP BY branch_id, year, month, ptype
                             }).each{|p|
      branch = @branch.find{|x| x.id == p.branch_id}
      month  = MONTHS[p.month-1]
      quarter = get_quarter(p.month)
      year   = (quarter==4 ? p.year-1 : p.year)

      data[branch][year]||= {}
      data[branch][year][quarter]||= {}
      data[branch][year][quarter][month] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      if data[branch][year][quarter][month]
        if p.ptype==1
          data[branch][year][quarter][month][3] += p.amount.round(2)
        elsif p.ptype==2
          data[branch][year][quarter][month][4] += p.amount.round(2)
        elsif p.ptype==3
          data[branch][year][quarter][month][5] += p.amount.round(2)
        end
      end
    }
    
    product_cond = "AND l.loan_product_id=#{self.loan_product_id}" if self.loan_product_id

    # loans disbursed
    repository.adapter.query(%Q{
                               SELECT c.branch_id branch_id, year(disbursal_date) year, month(disbursal_date) month, SUM(l.amount) amount
                               FROM loans l, clients cl, centers c
                               WHERE l.disbursal_date >= '#{from_date.strftime('%Y-%m-%d')}' and l.disbursal_date <= '#{to_date.strftime('%Y-%m-%d')}' #{product_cond}
                               AND   l.deleted_at is NULL AND l.client_id = cl.id AND cl.center_id=c.id AND c.branch_id in (#{branch_ids}) AND rejected_on is NULL
                               GROUP BY branch_id, month, year
                             }).each{|l|
      branch = @branch.find{|x| x.id == l.branch_id}
      month  = MONTHS[l.month-1]
      quarter = get_quarter(l.month)
      year   = (quarter==4 ? l.year-1 : l.year)

      data[branch][year]||= {}
      data[branch][year][quarter]||= {}
      data[branch][year][quarter][month] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      if data[branch][year][quarter][month]
        data[branch][year][quarter][month][2] += l.amount.round(2)
      end
    }

    # loans approved
    repository.adapter.query(%Q{
                               SELECT c.branch_id branch_id, year(approved_on) year, month(approved_on) month, 
                               SUM(if(l.amount_sanctioned>0, l.amount_sanctioned, l.amount)) amount
                               FROM loans l, clients cl, centers c
                               WHERE l.approved_on >= '#{from_date.strftime('%Y-%m-%d')}' and l.approved_on <= '#{to_date.strftime('%Y-%m-%d')}' #{product_cond}
                               AND   l.deleted_at is NULL AND l.client_id = cl.id AND cl.center_id=c.id AND c.branch_id in (#{branch_ids}) AND rejected_on is NULL
                               GROUP BY branch_id, month, year
                             }).each{|l|
      branch = @branch.find{|x| x.id == l.branch_id}
      month  = MONTHS[l.month-1]
      quarter = get_quarter(l.month)
      year   = (quarter==4 ? l.year-1 : l.year)

      data[branch][year]||= {}
      data[branch][year][quarter]||= {}
      data[branch][year][quarter][month] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      
      if data[branch][year][quarter][month]
        data[branch][year][quarter][month][1] += l.amount.round(2)
      end
    }

    # loans applied
    repository.adapter.query(%Q{
                               SELECT c.branch_id branch_id, year(applied_on) year, month(applied_on) month, 
                               SUM(if(l.amount_applied_for>0, l.amount_applied_for, l.amount)) amount
                               FROM loans l, clients cl, centers c
                               WHERE l.applied_on >= '#{from_date.strftime('%Y-%m-%d')}' and l.applied_on <= '#{to_date.strftime('%Y-%m-%d')}' #{product_cond}
                               AND   l.deleted_at is NULL AND l.client_id = cl.id AND cl.center_id=c.id AND c.branch_id in (#{branch_ids})
                               GROUP BY branch_id, month, year
                             }).each{|l|
      branch = @branch.find{|x| x.id == l.branch_id}
      month  = MONTHS[l.month-1]
      quarter = get_quarter(l.month)
      year   = (quarter==4 ? l.year-1 : l.year)
      
      data[branch][year]||= {}
      data[branch][year][quarter]||= {}
      data[branch][year][quarter][month] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      if data[branch][year][quarter][month]
        data[branch][year][quarter][month][0] += l.amount.round(2)
      end
    }
    
    return data
  end

  private
  def get_quarter(month)
    (month-1)/3 > 0 ? (month-1)/3 : 4
  end

end
