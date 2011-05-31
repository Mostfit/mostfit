class ClientAbsenteeismReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :more_than, :attendance_status, :days_percentage

  validates_with_method :branch_id, :branch_should_be_selected  
 
  def initialize(params,dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Client Absenteeism Report as on #{@date}"
    get_parameters(params, user)
  end

  def name
    "Client absenteeism as on #{@to_date}"
  end

  def self.name
    "Client Absenteeism Report"
  end

  def generate
    data, att, client_groups, clients = {}, {}, {}, {}
    num_more_than = @more_than ? @more_than : 0
    Attendance.all(:center => @center, :date.gte => @from_date, :date.lte => @to_date).aggregate(:fields => [:center_id, :client_id, :status, :client_id.count]).map{|center_id, client_id, status, count|
      att[client_id]||={}
      #att[client_id][0] = Client.get(client_id).loans(:disbursal_date => (@from_date..@to_date).to_a).count
      att[client_id][status.to_i] = count 
    }

    if @days_percentage == 2 # if percentage is the selection criteria
      att.each{|client_id, statuses|
        if not statuses[@attendance_status] or ((statuses[@attendance_status]/(statuses.values.inject{|sum , x| sum + x}).to_f)*100) <= num_more_than
          att.delete(client_id)        
        else
          att[client_id][0]=Client.get(client_id).loans(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).count
          #att[client_id][0]=Client.get(client_id).loans(:disbursal_date => (@from_date..@to_date).to_a).count
        end
     #att.delete(client_id) if not statuses[(@attendance_status)] or statuses[(@attendance_status)] <= num_more_than
      }
    else #if number of days is the selection criteria
      att.each{|client_id, statuses|
        if not statuses[@attendance_status] or statuses[@attendance_status] <= num_more_than
          att.delete(client_id)        
        else
          att[client_id][0]=Client.get(client_id).loans(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).count
        end
     #att.delete(client_id) if not statuses[(@attendance_status)] or statuses[(@attendance_status)] <= num_more_than
      }
    end

    client_ids = att.keys
    Client.all(:id => client_ids, :fields => [:id, :name, :reference, :client_group_id, :center_id]).each{|c|
      clients[c.center_id]||= []
      clients[c.center_id] << c
    }
    center_ids = clients.keys
    p @branch
    @branch.each do |branch|
      data[branch] = {}
      branch.centers.each do |center|
        next unless @center.find{|c| c.id==center.id}
        next unless clients.key?(center.id)
        next unless center_ids.include?(center.id)        
        data[branch][center] = {}
        center.client_groups.sort_by{|x| x.name}.each{|client_group|
          client_groups[client_group.id]=client_group
          data[branch][center][client_group.name] = {}
        }
        clients[center.id].each{|client|
          if client.client_group_id and group = client_groups[client.client_group_id]
            data[branch][center][group.name][client] = att[client.id]
          else
            data[branch][center]["No name"] = {}
            data[branch][center]["No name"][client] = att[client.id]            
          end
        }
      end
    end
    return data
  end
end
