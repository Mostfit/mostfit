class RepaymentOverdue < Report
  attr_accessor :date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id

  def initialize(params, dates, user)
    @date   = (dates and dates[:date]) ? dates[:date] : Date.today
    @name   = "Report as of #{@date}"
    if params
      @branch_id = params[:branch_id]
      @center_id = params[:center_id]
    end
    get_parameters(params, user)
  end

  def self.name
    "Repayment overdue register"
  end

  def name
    "Repayment overdue register as  of #{@date}"
  end

  def generate
    data, clients, loans, centers, branches, hash = {}, {}, {}, {}, {}, {}
    hash[:branch_id] = @branch.map{|x| x.id}
    hash[:center_id] = @center.map{|x| x.id}
    hash[:loan_product_id] = self.loan_product_id  if self.loan_product_id        
    histories = LoanHistory.defaulted_loan_info_by(:loan, @date, hash, ["branch_id", "center_id", "client_id"])

    if histories.length>0
      clients = Client.all(:id => histories.map{|x| x.client_id}, :fields => [:id, :name]).aggregate(:id, :name).to_hash
      loans   = Loan.all(:client_id => histories.map{|x| x.client_id}, :fields => [:id, :client_id, :amount]).aggregate(:id, :amount).to_hash
    end

    @branch.each{|b|
      data[b] = {}
      branches[b.id] = b
      b.centers.each{|c|
        centers[c.id] = c
        next if @center and not @center.include?(c)
        data[b][c] ||= {}
        histories.find_all{|x| x.branch_id == b.id and x.center_id == c.id}.each{|row|
          data[b][c][clients[row.client_id]] ||= []
          data[b][c][clients[row.client_id]] << [row.loan_id, loans[row.loan_id], row.pdiff, row.tdiff-row.pdiff, 0]
        }        
      }
    }
    
    fees_due         = Fee.overdue(@date)
    fees_due_loans   = Loan.all(:id => fees_due.keys, :fields => [:id, :client_id, :amount]) if fees_due.length>0
    fees_due_clients = Client.all(:id => fees_due_loans.map{|x| x.client_id}, :fields => [:id, :name, :center_id]).map{|c| [c.id, c]}.to_hash
    
    fees_due.each{|loan_id, amount|
      loan   = fees_due_loans.find{|x| x.id==loan_id}
      next unless loan
      client = fees_due_clients[loan.client_id]
      center = centers[client.center_id]
      next unless center
      branch = branches[center.branch_id]
      if data[branch][center][client.name] and row = data[branch][center][client.name].find{|x| x[0] == loan_id}
        row[4]+=amount
      else
        data[branch][center][client.name] = [[loan_id, loan.amount, 0, 0 , amount]]
      end
    }

    Fee.all(:payable_on => [:client_date_joined, :client_grt_pass_date]).each{|fee| 
      client_paid    = Payment.all(:type => :fees, :fee => fee, :amount => fee.amount).aggregate(:client_id)
      client_payable = Client.all(:client_type => fee.client_types, :fields => [:id], :center => @center).map{|x| x.id}
      clients        = Client.all(:id => (client_payable - client_paid), :fields => [:id, :name, :center_id])      
      clients.each{|client|
        center = centers[client.center_id]
        next unless center
        branch = branches[center.branch_id]
        if data[branch][center][client.name] and row = data[branch][center][client.name].first
          row[4]+=fee.amount
        else
          data[branch][center][client.name] = [[0, 0, 0, 0 , fee.amount]]
        end
      }
    }

    return data
  end
end
