class QuaterConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :branch, :branch_id, :loan_product_id
  QUATERS = {1 => [:april, :may, :june], 2 => [:july, :august, :september], 3 => [:october, :november, :december], 4 => [:january, :february, :march]}
  MONTHS  = [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.min_date
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.new(Date.today.year, Date.today.month-1, -1)
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end
  
  def name
    "Quater wise Consolidated Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Quater wise Consolidated report"
  end
  
  def generate
    data = {}
    this_year = Date.today.year
    this_month = Date.today.month
#    histories = LoanHistory.sum_outstanding_by_month(self.from_date, self.to_date, self.loan_product_id)
    @branch.each{|branch|
      data[branch]||= {}
      (branch.creation_date.year..this_year).each{|y|
        QUATERS.each{|quater, months|
          year = (quater==4 ? y-1 : y)
          months.each{|month|
            month_number = MONTHS.index(month) + 1
            # we do not generate report for the ongoing month
            next if year==this_year and month_number >= this_month
            histories = LoanHistory.sum_outstanding_by_month(month_number, year, branch, self.loan_product_id)
            next if not histories
            data[branch][year]||= {}
            data[branch][year][quater]||= {}
            
            #0        1          2                3              4          5     6                  7       8    9,10,11     12,13,14   15
            #applied, sanctioned,disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults, name      
            data[branch][year][quater][month] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

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
            
            data[branch][year][quater][month][7] += principal_actual
            data[branch][year][quater][month][9] += total_actual
            data[branch][year][quater][month][8] += total_actual - principal_actual
          
            data[branch][year][quater][month][10]  += (principal_actual > principal_scheduled ? principal_actual-principal_scheduled : 0)
            data[branch][year][quater][month][11] += ((total_actual-principal_actual) > (total_scheduled-principal_scheduled) ? (total_actual-principal_actual - (total_scheduled-principal_scheduled)) : 0)
            data[branch][year][quater][month][12] += total_actual > total_scheduled ? total_actual - total_scheduled : 0
            
            data[branch][year][quater][month][13]  += principal_advance
            data[branch][year][quater][month][15] += total_advance
            data[branch][year][quater][month][14] += (total_advance - principal_advance)
          }
        }
      }
    }
    # payments
    repository.adapter.query(%Q{
                               SELECT c.branch_id branch_id, year(received_on) year, month(received_on) month, p.type ptype, SUM(amount) amount
                               FROM payments p, clients cl, centers c
                               WHERE p.received_on >= '#{from_date.strftime('%Y-%m-%d')}' and p.received_on <= '#{to_date.strftime('%Y-%m-%d')}'
                               AND p.deleted_at is NULL AND p.client_id = cl.id AND cl.center_id=c.id
                               GROUP BY branch_id, year, month, ptype
                             }).each{|p|
      branch = @branch.find{|x| x.id == p.branch_id}
      month  = MONTHS[p.month-1]
      quater = get_quater(p.month)
      year =   p.year

      data[branch][year]||= {}
      data[branch][year][quater]||= {}
      data[branch][year][quater][month] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      if data[branch][year][quater][month]
        if p.ptype==1
          data[branch][year][quater][month][3] += p.amount.round(2)
        elsif p.ptype==2
          data[branch][year][quater][month][4] += p.amount.round(2)
        elsif p.ptype==3
          data[branch][year][quater][month][5] += p.amount.round(2)
        end
      end
    }

    # loans disbursed
    repository.adapter.query(%Q{
                               SELECT c.branch_id branch_id, year(disbursal_date) year, month(disbursal_date) month, SUM(l.amount) amount
                               FROM loans l, clients cl, centers c
                               WHERE l.disbursal_date >= '#{from_date.strftime('%Y-%m-%d')}' and l.disbursal_date <= '#{to_date.strftime('%Y-%m-%d')}'
                               AND   l.deleted_at is NULL AND l.client_id = cl.id AND cl.center_id=c.id
                               GROUP BY branch_id, month, year
                             }).each{|l|
      branch = @branch.find{|x| x.id == l.branch_id}
      month  = MONTHS[l.month-1]
      quater = get_quater(l.month)

      data[branch][l.year]||= {}
      data[branch][l.year][quater]||= {}
      data[branch][l.year][quater][month] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      if data[branch][l.year][quater][month]
        data[branch][l.year][quater][month][2] += l.amount.round(2)
      end
    }

    # loans approved
    repository.adapter.query(%Q{
                               SELECT c.branch_id branch_id, year(approved_on) year, month(approved_on) month, SUM(l.amount) amount
                               FROM loans l, clients cl, centers c
                               WHERE l.approved_on >= '#{from_date.strftime('%Y-%m-%d')}' and l.approved_on <= '#{to_date.strftime('%Y-%m-%d')}'
                               AND   l.deleted_at is NULL AND l.client_id = cl.id AND cl.center_id=c.id
                               GROUP BY branch_id, month, year
                             }).each{|l|
      branch = @branch.find{|x| x.id == l.branch_id}
      month  = MONTHS[l.month-1]
      quater = get_quater(l.month)

      data[branch][l.year]||= {}
      data[branch][l.year][quater]||= {}
      data[branch][l.year][quater][month] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      
      if data[branch][l.year][quater][month]
        data[branch][l.year][quater][month][1] += l.amount.round(2)
      end
    }

    # loans applied
    repository.adapter.query(%Q{
                               SELECT c.branch_id branch_id, year(applied_on) year, month(applied_on) month, SUM(l.amount) amount
                               FROM loans l, clients cl, centers c
                               WHERE l.applied_on >= '#{from_date.strftime('%Y-%m-%d')}' and l.applied_on <= '#{to_date.strftime('%Y-%m-%d')}'
                               AND   l.deleted_at is NULL AND l.client_id = cl.id AND cl.center_id=c.id
                               GROUP BY branch_id, month, year
                             }).each{|l|
      branch = @branch.find{|x| x.id == l.branch_id}
      month  = MONTHS[l.month-1]
      quater = get_quater(l.month)
      
      data[branch][l.year]||= {}
      data[branch][l.year][quater]||= {}
      data[branch][l.year][quater][month] ||= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      if data[branch][l.year][quater][month]
        data[branch][l.year][quater][month][0] += l.amount.round(2)
      end
    }
    
    return data
  end

  private
  def get_quater(month)
    (month-1)/3 > 0 ? (month-1)/3 : 4
  end

end
