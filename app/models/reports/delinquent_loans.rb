class DelinquentLoanReport < Report
  attr_accessor :branch, :center, :branch_id, :center_id, :staff_member_id

  def initialize(params,dates, user)
    @name   = "Delinquent Loans Report"
    get_parameters(params, user)
  end

  def name
    "Delinquent Loans"
  end

  def self.name
    "Delinquent Loan Report"
  end

  def generate
    data, clients, loans, lids = {}, {}, {}, []

    Client.all(:tags => :insincere, :fields => [:client_group_id, :center_id, :id, :tags, :name]).each{|c|
      clients[c.center_id]||=[]
      clients[c.center_id] << c
    }
    Loan.all(:client => clients.values.flatten, :disbursal_date.not => nil).each{|l|
      loans[l.client_id] = l
      lids << l.id
    }


    if lids.length>0
      principals = Payment.all(:loan_id => lids, :type => :principal).aggregate(:client_id, :amount.sum).to_hash
      interests  = Payment.all(:loan_id => lids, :type => :interest).aggregate(:client_id, :amount.sum).to_hash
      fees       = Payment.all(:loan_id => lids, :type => :fees).aggregate(:client_id, :amount.sum).to_hash
    else 
      principals, interests, fees = {}, {}, {}
    end
    
    @branch.each do |branch|
      data[branch] = {}
      branch.centers.each do |center|
        next unless @center.find{|c| c.id==center.id}
        next unless clients[center.id]

        data[branch][center] = {}
        center.client_groups.sort_by{|x| x.name}.each{|client_group|
          data[branch][center][client_group.name] = []
        }
        
        clients[center.id].each{ |client|
          principal  = principals[client.id] if principals
          interest   = interests[client.id]  if interests
          fee        = fees[client.id] if fees
          next unless loans.key?(client.id)
          loan     = loans[client.id]
          
          if client.client_group_id and group = client.client_group            
            data[branch][center][group.name] ||= []
            data[branch][center][group.name] << [client.reference, client.name, loan.loan_product.name, loan.amount, principal, interest, fee]
          else
            data[branch][center]["No name"] ||= []
            data[branch][center]["No name"] << [client.reference, client.name, loan.loan_product.name, loan.amount,  principal, interest, fee]
          end
        }
      end
    end

    return data
  end
end
