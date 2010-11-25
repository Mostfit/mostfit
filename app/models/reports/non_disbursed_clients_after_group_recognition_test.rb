#This is spec for clients whose GRT has been done but the loan has not been disbursed

class NonDisbursedClientsAfterGroupRecognitionTest < Report
  attr_accessor :date, :branch, :center, :staff_member_id, :branch_id, :center_id, :late_by_days

  def initialize(params, dates, user)
    @date = dates.blank? ? Date.today : dates[:date]
    @name = "Clients whoose GRT has been done but loans not disbursed till #{@date}"
    @late_by_days = 7
    get_parameters(params, user)
  end

  def name
    "Non disbursed clients after GRT"
  end
  
  def self.name
    "Non disbursed clients after GRT"
  end
  
  def generate
    data = {}
    client_ids = (Client.all(:fields => [:id], :grt_pass_date.not => nil, :date_joined.lte => @date).map{|c| c.id} - Loan.all(:disbursal_date.not => nil, :disbursal_date.lte => @date + self.late_by_days).map{|l| l.client_id})    
    clients = Client.all(:id => client_ids, :fields => [:id, :name, :reference, :date_joined, :grt_pass_date, :center_id]).group_by{|client|     
      client.center_id
    }
    loans = Loan.all(:client_id => client_ids, :fields => [:id, :client_id, :scheduled_disbursal_date, :disbursal_date]).map{|l| [l.client_id, l.scheduled_disbursal_date, l.disbursal_date]}.to_hash
    @branch.each{|b|
      data[b]||= {}
      b.centers.each{|c|
        next unless clients.key?(c.id)
        next if @center and not @center.find{|x| x.id==c.id}
        data[b][c] ||= []
        clients[c.id].each{|client|
          temp = (((loans[client.id] ? loans[client.id] : @date) - client.grt_pass_date).abs)
          if temp > 0 : temp1 = temp
            data[b][c] << [client.id, client.reference, client.name, client.date_joined, client.grt_pass_date, loans[client.id],temp1]
          end
        }
      }
    }
    return data
  end
end  
