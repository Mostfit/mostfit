class ConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :funder, :branch_id, :center_id, :staff_member_id, :loan_product_id, :funder_id, :report_by_loan_disbursed, :funding_line, :funding_line_id, :loan_cycle
  attr_reader   :data

  include Mostfit::Reporting

  column :'branch / center'
  column :loan_amount         => [:applied,   :sanctioned, :disbursed         ]
  column :repayment           => [:principal, :interest,   :fee,        :total]
  column :balance_outstanding => [:principal, :interest,   :total             ]
  column :balance_overdue     => [:principal, :interest,   :total             ]
  column :advance_repayment   => [:collected, :adjusted,   :balance           ]

  validates_with_method :from_date, :date_should_not_be_in_future

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end
  
  def name
    "Consolidated Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Consolidated report"
  end
  
  def generate
    debugger
    branches, centers, data, clients, loans = {}, {}, {}, {}, {}
    extra, funder_loan_ids = get_extra

    grouper = [:branch]    
    grouper.push(:center)       if self.branch_id
    grouper.push(:client_group) if self.center_id
    group_by_column = (grouper.last.to_s + "_id").to_sym
    
    histories = (LoanHistory.sum_outstanding_grouped_by(self.to_date, grouper, extra)||{}).group_by{|x| x.send(group_by_column)}
    advances  = (LoanHistory.sum_advance_payment(self.from_date, self.to_date, grouper, extra)||{}).group_by{|x| x.send(group_by_column)}
    balances  = (LoanHistory.advance_balance(self.to_date, grouper, extra)||{}).group_by{|x| x.send(group_by_column)}
    old_balances = (LoanHistory.advance_balance(self.from_date-1, grouper, extra)||{}).group_by{|x| x.send(group_by_column)}
    defaults   = LoanHistory.defaulted_loan_info_by(grouper, @to_date, extra).group_by{|x| x.send(group_by_column)}.map{|cid, row| [cid, row[0]]}.to_hash
    
    @center.each{|c| centers[c.id] = c} if self.branch_id

    if self.center_id
      groups = {}
      @center = Center.get(center_id)
      @center.client_groups.each{|g|
        groups[g.id] = g
      }
    end

    @branch.each{|b|
      branches[b.id] = b
      
      if self.branch_id
        data[b]||= {}
        b.centers.each{|c|
          next unless centers.key?(c.id)
          centers[c.id]  = c
          if self.center_id
            data[b][c]||= {}
            c.client_groups.each{|g|
              add_outstanding_to(data[b][c], g, histories, advances, balances, old_balances, defaults)
            }
          else
            add_outstanding_to(data[b], c, histories, advances, balances, old_balances, defaults)
          end
        }
      else
        #0              1                 2                3              4              5     6                  7         8    9,10,11     12       
        #amount_applied,amount_sanctioned,amount_disbursed,outstanding(p),outstanding(i),total,principal_paidback,interest_,fee_,shortfalls, #defaults
        add_outstanding_to(data, b, histories, advances, balances, old_balances, defaults)
      end
    }

    froms, extra_condition = get_payment_extra_and_froms(centers, funder_loan_ids)
    group_by_query = grouper.map{|x| "#{x.to_s}_id"}.join(", ")
    repository.adapter.query(%Q{
                               SELECT p.received_by_staff_id staff_id, c.branch_id branch_id, type ptype, SUM(p.amount) amount, #{group_by_query}
                               FROM #{froms}
                               WHERE p.received_on >='#{from_date.strftime('%Y-%m-%d')}' and p.received_on <= '#{to_date.strftime('%Y-%m-%d')}'AND p.deleted_at is NULL
                                     AND cl.center_id=c.id AND cl.deleted_at is NULL AND p.client_id=cl.id #{extra_condition}
                               GROUP BY #{group_by_query}, p.type
                             }).each{|p|      
      if branch = branches[p.branch_id] 
        if self.branch_id and center = centers[p.center_id]
          if self.center_id
            group = groups[p.client_group_id]
            add_payments_to(data[branch][center], group, p)
          else
            add_payments_to(data[branch], center, p)
          end
        else
          add_payments_to(data, branch, p)
        end
      end
    }

    # Applied on, Approved on, Disbursed on
    {:applied_on => [:amount_applied_for, 0], :approved_on => [:amount_sanctioned, 1], :disbursal_date => [:amount, 2]}.each do |event, cols|
      hash = {event.gte => from_date, event.lte => to_date}
      hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
      hash["l.id"]           = funder_loan_ids if funder_loan_ids and funder_loan_ids.length > 0      
      hash["l.cycle_number"] = @loan_cycle if @loan_cycle and not @loan_cycle.nil?
      group_by_query = ["c.branch_id"]
      group_by_query.push("cl.center_id") if self.branch_id
      group_by_query.push("cl.client_group_id") if self.center_id
      
      group_loans(group_by_query.join(", "), "sum(if(#{cols[0]}>0, #{cols[0]}, amount)) amount", hash).group_by{|x| 
        x.branch_id
      }.each{|branch_id, rows|
        next if not branches.key?(branch_id)
        branch = branches[branch_id]
        
        if self.branch_id and not self.center_id
          rows.group_by{|x| x.center_id}.each{|center_id, row|
            next if not centers.key?(center_id)
            center = centers[center_id]
            add_to_result(data[branch], center, cols[1], row[0].amount) if row[0] and row[0].amount
          }
        elsif self.branch_id and self.center_id
          rows.group_by{|x| x.client_group_id}.each{|client_group_id, row|
            group = groups[client_group_id]
            next if not centers.key?(row[0].center_id)
            center = centers[center_id]    
            add_to_result(data[branch][center], group, cols[1], row[0].amount) if row[0] and row[0].amount
          }
        else
          add_to_result(data, branch, cols[1], rows[0].amount) if rows[0] and rows[0].amount
        end
      }
    end
    @data = data
  end
end
