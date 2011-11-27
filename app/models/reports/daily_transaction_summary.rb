class DailyTransactionSummary < Report
  attr_accessor :date, :branch_id
  
  DataRow = Struct.new(:disbursement, :collection, :foreclosure, :var_adjustment, :claim_settlement, :write_off)

  def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @name   = "Report for #{@date}"
    get_parameters(params, user)
  end
  
  def name
    "Daily transaction summary for #{@date}"
  end
  
  def self.name
    "Daily transaction summary"
  end
  
  def generate
    objects, data = {}, {}
    extra = []

    if @branch_id.nil?
      grouper = :branch
      @grouper_objects = Branch.all.sort
    else
      grouper = :center
      @grouper_objects = Center.all(:branch_id => @branch_id).sort
    end

    grouper_id = (grouper.to_s + '_id')

    advances  = (LoanHistory.sum_advance_payment(self.date, self.date, grouper, extra)||{}).group_by{|x| x.send(grouper_id)}
    balances  = (LoanHistory.advance_balance(self.date, grouper, extra)||{}).group_by{|x| x.send(grouper_id)}
    old_balances = (LoanHistory.advance_balance(self.date-1, grouper, extra)||{}).group_by{|x| x.send(grouper_id)}

    collections   = {:principal => {}, :interest => {}, :fees => {}}
    LoanHistory.sum_repayment_grouped_by(grouper, @date, @date).each{|type, objects|
      collections[type] = objects.map{|go| [go.send(grouper_id), go.amount]}.to_hash
    }
   
    #foreclosures as calculated because there is a doubt that Loan History is getting created properly. for instance prepayment is not recoreded as a preclosure
    foreclosures  = LoanHistory.all(:status => :repaid,  :date => @date, :scheduled_outstanding_principal.gt => 0).aggregate(grouper_id.to_sym, :principal_paid.sum, :interest_paid.sum).map{|x| [x[0], [x[1], x[2]]]}.to_hash
    
    # preclosures calculated if the Loan History get created properly. A pre-payment has to be recorded as a preclosure.
    # NOTE: until we are sure about the that Loan History is recording preclosures correctly we will have to use the above foreclosures code.
    preclosures_composite_keys = LoanHistory.all(:status => :preclosed, :last_status => :outstanding, :date => @date).aggregate(:composite_key)
    unless preclosures_composite_keys.empty?
      pck = preclosures_composite_keys.map{|x| x-0.0001}
      precloures    = LoanHistory.all(:composite_key => pck).aggregate(grouper_id.to_sym, 
                                                                       :actual_outstanding_principal.sum, 
                                                                       :actual_outstanding_total.sum).map{|x| [x[0], [x[1], x[2]]]}.to_hash
    end

    # calculation of written off outstanding. Once the Loan gets written off the corresponding LoanHistory entry with the written_off status shows loan_outstanding as zero
    write_offs_composite_keys = LoanHistory.all(:status => :written_off, :last_status => :outstanding, :date => @date).aggregate(:composite_key)
    unless write_offs_composite_keys.empty?
      wock = write_offs_composite_keys.map{|x| x-0.0001}
      write_offs    = LoanHistory.all(:composite_key => wock).aggregate(grouper_id.to_sym, 
                                                                        :actual_outstanding_principal.sum, 
                                                                        :actual_outstanding_total.sum).map{|x| [x[0], [x[1], x[2]]]}.to_hash
    end

    # calculation of claim-settlement outstanding. This is again similar to the written-off process
    claimed_composite_keys = LoanHistory.all(:status => :claim_settlement, :last_status => :outstanding, :date => @date).aggregate(:composite_key)
    unless claimed_composite_keys.empty?
      cck = claimed_composite_keys.map{|x| x-0.0001}
      claimed       = LoanHistory.all(:composite_key => cck).aggregate(grouper_id.to_sym, 
                                                                       :actual_outstanding_principal.sum, 
                                                                       :actual_outstanding_total.sum).map{|x| [x[0], [x[1], x[2]]]}.to_hash
    end
    collections = {}
    #var_adjustments = old_balances - balances + advances
    @grouper_objects.each{|go|
      clients = go.clients.aggregate(:id) rescue []
      collections[go.id] = {:principal => 0, :interest => 0, :fees => 0}
      unless clients.empty?
        payment_principal = Payment.all(:client_id => clients, :received_on => @date, :type => :principal).aggregate(:amount.sum)
        payment_interest = Payment.all(:client_id => clients, :received_on => @date, :type => :interest).aggregate(:amount.sum)
        payment_fees = Payment.all(:client_id => clients, :received_on => @date, :type => :fees).aggregate(:amount.sum)
        collections[go.id] = {:principal => payment_principal, :interest => payment_interest, :fees => payment_fees} 
      end
      
      data[go] ||= DataRow.new(0, {:principal => 0, :interest => 0, :fees => 0, :var => 0, :total => 0}, 
                               {:principal => 0, :interest => 0, :total => 0}, {:principal => 0, :interest => 0, :total => 0}, 
                               {:principal => 0, :interest => 0, :total => 0}, {:principal => 0, :interest => 0, :total => 0})
      
      data[go][0] += 0
      data[go][0] += (Loan.all(:client_id => clients, :disbursal_date => @date).aggregate(:amount).first || 0) unless clients.empty?

      # collection
      data[go][1][:principal] += ((collections[go.id][:principal] || 0) - ( advances.key?(go.id) ? (advances[go.id][0][0] || 0) : 0 )) 
      data[go][1][:interest]  += ((collections[go.id][:interest] || 0) - 
                (( advances.key?(go.id) ? (advances[go.id][0][1] || 0) : 0 ) - ( advances.key?(go.id) ? (advances[go.id][0][0] || 0) : 0 )))
      data[go][1][:fees] += collections[go.id][:fees] || 0 
      data[go][1][:total] += data[go][1][:principal] + data[go][1][:interest] + data[go][1][:fees]

      # foreclosure
      if foreclosures.key?(go.id)
        data[go][2][:principal] += foreclosures[go.id][0] || 0
        data[go][2][:interest]  += foreclosures[go.id][1] || 0
        data[go][2][:total]     += ((foreclosures[go.id][1] || 0) + (foreclosures[go.id][0] || 0))
      end

      # var adjusted
      if advances.key?(go.id)
        data[go][1][:var] += advances[go.id][0][1] || 0  
        data[go][1][:total] += (advances[go.id][0][1] || 0)    
        principal = ((advances[go.id][0][0] || 0) + 
                     (old_balances.key?(go.id) ? (old_balances[go.id][0][0] || 0) : 0) - 
                    (balances.key?(go.id) ? (balances[go.id][0][0] || 0) : 0 ))
        total = ((advances[go.id][0][1] || 0) + 
                 (old_balances.key?(go.id) ? (old_balances[go.id][0][1] || 0) : 0) - 
                (balances.key?(go.id) ? (balances[go.id][0][1] || 0) : 0 ))
        data[go][3][:principal] += principal
        data[go][3][:interest]  += (total - principal)
        data[go][3][:total] += total
      end

      # claimed or death settlement
       if claimed && claimed.key?(go.id)
        data[go][4][:principal] += claimed[go.id][0] || 0
        data[go][4][:interest]  += ((claimed[go.id][1] || 0) - (claimed[go.id][0] || 0))
        data[go][4][:total]     += claimed[go.id][1] || 0
      end
      
      # written off
      if write_offs && write_offs.key?(go.id)
        data[go][5][:principal] += write_offs[go.id][0] || 0
        data[go][5][:interest]  += ((write_offs[go.id][1] || 0) - (write_offs[go.id][0] || 0))
        data[go][5][:total]     += write_offs[go.id][1] || 0
      end
    } 
    return data
  end
end
