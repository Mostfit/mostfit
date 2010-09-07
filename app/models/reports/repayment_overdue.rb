class RepaymentOverdue < Report
  attr_accessor :date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id

  def initialize(params, dates, user)
    @date   = (dates and dates[:date]) ? dates[:date] : Date.today
    @name   = "Report as of #{@date}"
    @branch_id = params[:branch_id]
    @center_id = params[:center_id]
    get_parameters(params, user)
  end

  def self.name
    "Repayment overdue register"
  end

  def name
    "Repayment overdue register as  of #{@date}"
  end

  def generate
    data, clients, loans, hash = {}, {}, {}, {}
    hash[:branch_id] = @branch.map{|x| x.id}
    hash[:center_id] = @center.map{|x| x.id}
    hash[:loan_product_id] = self.loan_product_id  if self.loan_product_id        
    histories = LoanHistory.defaulted_loan_info_by(:loan, @date, hash, ["branch_id", "center_id", "client_id"])

    clients = Client.all(:center => @center).aggregate(:id, :name).to_hash
    loans   = Loan.all(:client_id => clients.keys).aggregate(:id, :amount).to_hash

    @branch.each{|b|
      data[b] = {}
      b.centers.each{|c|
        next if @center and not @center.include?(c)
        data[b][c] = {}
        histories.find_all{|x| x.branch_id == b.id and x.center_id == c.id}.each{|row|          
          data[b][c][clients[row.client_id]] ||= []
          data[b][c][clients[row.client_id]] << [row.loan_id, loans[row.loan_id], row.pdiff, row.tdiff-row.pdiff, 0]
        }        
      }
    }
    
    fees_due = Fee.overdue(@date)
    fees_due_loans = Loan.all(:id => fees_due.keys) if fees_due.length>0

    fees_due.each{|loan_id, amount|
      next unless loans.key?(loan_id)
      client = fees_due_loans.find{|x| x.id==loan_id}.client
      center = client.center
      branch = center.branch
      if data[branch][center][client.name] and row = data[branch][center][client.name].find{|x| x[0] == loan_id}
        row[4]+=amount
      else
        data[branch][center][client.name] = [[loan_id, loans[loan_id], 0, 0 , amount]]
      end
    }
    return data
  end
end
