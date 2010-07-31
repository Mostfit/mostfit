class ClientAbsenteeismReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :absent_more_than, :attendance_status

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
    @absent_more_than = 4 unless @absent_more_than

    Attendance.all(:center => @center, :date.gte => @from_date, :date.lte => @to_date, :status => :absent).aggregate(:fields => [:center_id, :client_id, :status, :client_id.count]).map{|center_id, client_id, status, count|
      att[client_id]||={}
      att[client_id][status.to_i]=count
    }
    att.each{|client_id, statues|
      att.delete(client_id) if not statues[4] or statues[4] <= @absent_more_than
    }
    client_ids = att.keys
    Client.all(:id => client_ids, :fields => [:id, :name, :reference, :client_group_id, :center_id]).each{|c|
      clients[c.center_id]||= []
      clients[c.center_id] << c
    }
    center_ids = clients.keys

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
