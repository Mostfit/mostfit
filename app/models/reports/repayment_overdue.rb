class RepaymentOverdue < Report
  attr_accessor :date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id, :funder_id

  validates_with_method :branch_id, :branch_should_be_selected  

  def initialize(params, dates, user)
    @date   = (dates and dates[:date]) ? dates[:date] : Date.today
    @name   = "Report as of #{@date}"
    get_parameters(params, user)
  end

  def self.name
    "Repayment overdue register"
  end

  def name
    "Repayment overdue register as  of #{@date}"
  end

  def generate
    data, clients, loans, centers, branches, payments, hash = {}, {}, {}, {}, {}, {:principal => {}, :interest => {}, :fees => {}}, {}
    hash[:branch_id] = @branch.map{|x| x.id}
    hash[:center_id] = @center.map{|x| x.id}
    hash[:loan_product_id] = self.loan_product_id  if self.loan_product_id

    # if a funder is selected
    funder_loan_ids = @funder.loan_ids if @funder
    hash[:id]       = funder_loan_ids if @funder
    histories = LoanHistory.defaulted_loan_info_by(:loan, @date, hash, ["branch_id", "center_id", "client_id", "actual_outstanding_principal"])

    if histories and histories.length > 0
      client_ids = histories.map{|x| x.client_id}
      clients  = Client.all(:id => client_ids, :fields => [:id, :name]).map{|x| [x.id, x]}.to_hash
      loans    = Loan.all(:client_id => client_ids, :fields => [:id, :client_id, :amount]).aggregate(:id, :amount).to_hash
      payments[:principal] = Payment.all(:loan_id => loans.keys, :type => :principal).aggregate(:loan_id, :amount.sum).to_hash
      payments[:interest]  = Payment.all(:loan_id => loans.keys, :type => :interest).aggregate(:loan_id, :amount.sum).to_hash
      payments[:fees]      = Payment.all(:loan_id => loans.keys, :type => :fees).aggregate(:loan_id, :amount.sum).to_hash
    end
    
    histories = histories.group_by{|x| x.center_id}

    # get all the loan dues
    @branch.each{|b|
      data[b] = {}
      branches[b.id] = b
      b.centers.each{|c|
        centers[c.id] = c
        next if @center and not @center.include?(c)
        data[b][c] ||= {}
        histories[c.id].each{|row|
          data[b][c][clients[row.client_id]] ||= []
          prin  = payments[:principal][row.loan_id]||0
          int   = payments[:interest][row.loan_id]||0
          fee   = payments[:fees][row.loan_id]||0
          total = prin + int + fee
          data[b][c][clients[row.client_id]] << [row.loan_id, loans[row.loan_id], prin, int, fee, total,                                                 
                                                 loans[row.loan_id] - prin,
                                                 row.pdiff, row.tdiff-row.pdiff, 0]
        } if histories[c.id]
      }
    }

    # all the fee dues
    fees_due         = Fee.overdue(@date)
    fees_due_keys    = fees_due.keys & funder_loan_ids if @funder
    fees_due_loans   = fees_due.length > 0 ? Loan.all(:id => fees_due_keys, :fields => [:id, :client_id, :amount]) : []
    fees_due_clients = Client.all(:id => fees_due_loans.map{|x| x.client_id}, :fields => [:id, :name, :center_id]).map{|c| [c.id, c]}.to_hash
    
    fees_due.each{|loan_id, amount|
      loan   = fees_due_loans.find{|x| x.id==loan_id}
      next unless loan
      client = fees_due_clients[loan.client_id]
      center = centers[client.center_id]
      next unless center
      branch = branches[center.branch_id]
      if data[branch][center][client] and row = data[branch][center][client].find{|x| x[0] == loan_id}
        row[9]+=amount
      else
        data[branch][center][client] = [[loan_id, loan.amount, 0, 0, 0, 0, loan.amount, 0, 0, amount]]
      end
    }

    # client fee dues
    Fee.all(:payable_on => [:client_date_joined, :client_grt_pass_date]).each{|fee| 
      client_paid    = Payment.all(:type => :fees, :fee => fee, :amount => fee.amount).aggregate(:client_id)
      
      hash           = {:client_type => fee.client_types, :fields => [:id], :center => @center}
      hash[:id]      = Loan.all(:fields => [:id, :client_id], :id => funder_loan_ids).map{|x| x.client_id} if @funder

      # set appropriate filter for client GRT pass date or date joined depending on the fee
      fee.payable_on == :client_grt_pass_date ? hash[:grt_pass_date.lte] = @date : hash[:date_joined.lte] = @date 

      client_payable = Client.all(hash).map{|x| x.id}

      # get clients which have a payable but have not paid
      clients        = Client.all(:id => (client_payable - client_paid), :fields => [:id, :name, :center_id])      
      clients.each{|client|
        center = centers[client.center_id]
        next unless center
        branch = branches[center.branch_id]
        if data[branch][center][client] and row = data[branch][center][client].first
          row[9]+=fee.amount
        else
          data[branch][center][client] = [[0, 0, 0, 0, 0, 0, 0, 0, 0, fee.amount]]
        end
      }
    }

    return data
  end
end
