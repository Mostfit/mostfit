class LoanSizePerManagerReport < Report
  attr_accessor :from_date, :to_date, :branch, :branch_id

  def initialize(params,dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.min_date
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name      = "Average Loan Size per Center Manager Report"
    get_parameters(params, user)
  end

  def name
    "Average Loan Size Report"
  end

  def self.name
    "Average Loan Size Report"
  end

  def generate
    data, staff = {}, {}

    @branch.each{|branch|
      data[branch] = {}
    }
    StaffMember.all.each{|x| staff[x.id]=x}
    @branch.each{|branch|
      branch.centers.group_by{|c| c.manager}.each{|s, centers|
        clients_count = Loan.all(:applied_by => s, :fields => [:id, :client_id]).map{|x| x.client_id}.uniq.length
        data[branch][s] = [centers.count, clients_count, 0, 0, 0, 0, 0]
      }
    }

    disbursal_data.each{|x|
      next unless branch = @branch.find{|b| b.id==x.branch_id}
      s = staff[x.manager_id]
      if not data[branch][staff[x.manager_id]]
        clients_count = Loan.all(:applied_by => s, :fields => [:id, :client_id]).map{|l| l.client_id}.uniq.length
        data[branch][s] = [Center.all(:manager => s).count, clients_count, 0, 0, 0, 0, 0]
      end
      data[branch][s][2] = 0
      data[branch][s][3] = 0
      data[branch][s][4] = x.amount
    }

    approval_data.each{|x|
      next unless branch = @branch.find{|b| b.id==x.branch_id}
      unless data[branch][staff[x.manager_id]] 
        centers = staff[x.manager_id].centers
        clients_count = Loan.all(:applied_by => s, :fields => [:id, :client_id]).map{|l| l.client_id}.uniq.length
        data[branch][staff[x.manager_id]] = [centers.count, clients_count, 0, 0, 0, 0, 0]
      end
      data[branch][staff[x.manager_id]][3]  += x.amount
    }

    applied_data.each{|x|
      next unless branch = @branch.find{|b| b.id==x.branch_id}
      unless data[branch][staff[x.manager_id]] 
        centers = staff[x.manager_id].centers
        clients_count = Loan.all(:applied_by => s, :fields => [:id, :client_id]).map{|l| l.client_id}.uniq.length
        data[branch][staff[x.manager_id]] = [centers.count, clients_count, 0, 0, 0, 0, 0]
      end
      data[branch][staff[x.manager_id]][2] += x.amount
    }
    @branch.each{|branch|
      branch.centers.each{|center|
        next if data[branch] and data[branch][center.manager]
        data[branch][center.manager] = [center.manager.centers.count, 0, 0, 0, 0, 0, 0]
      }
      data[branch].each{|s, d|
        data[branch][s][5] = data[branch][s][1]>0 ? data[branch][s][4]/data[branch][s][1] : 0
        data[branch][s][6] = data[branch][s][0]>0 ? data[branch][s][4]/data[branch][s][0] : 0
      }
    }
    return data
  end
  
  private
  def disbursal_data
      repository.adapter.query(%Q{
                               SELECT st.id manager_id, st.name name, COUNT(DISTINCT(c.id)) center_count, COUNT(DISTINCT(cl.id)) client_count, 
                               SUM(l.amount) amount, AVG(l.amount) lavg, c.branch_id branch_id
                               FROM  centers c, clients cl, loans l, staff_members st
                               WHERE  st.id=l.disbursed_by_staff_id AND l.disbursal_date IS NOT NULL AND rejected_on is NULL
                               AND l.disbursal_date>='#{@from_date.strftime('%Y-%m-%d')}' AND l.disbursal_date<='#{@to_date.strftime('%Y-%m-%d')}'
                               AND l.deleted_at IS NULL AND l.client_id=cl.id AND cl.deleted_at IS NULL AND cl.center_id=c.id
                               GROUP BY st.id
                              })
  end

  def approval_data
    repository.adapter.query(%Q{
                               SELECT st.id manager_id, st.name name, SUM(l.amount) amount, c.branch_id branch_id
                               FROM  centers c, clients cl, loans l, staff_members st
                               WHERE  st.id=l.approved_by_staff_id AND l.approved_on IS NOT NULL AND rejected_on is NULL
                               AND l.approved_on>='#{@from_date.strftime('%Y-%m-%d')}' AND l.approved_on<='#{@to_date.strftime('%Y-%m-%d')}'
                               AND l.deleted_at IS NULL AND l.client_id=cl.id AND cl.deleted_at IS NULL AND cl.center_id=c.id
                               GROUP BY st.id
                              })
  end
  
  def applied_data
    repository.adapter.query(%Q{
                               SELECT st.id manager_id, st.name name, SUM(l.amount) amount, c.branch_id branch_id
                               FROM  centers c, clients cl, loans l, staff_members st
                               WHERE  st.id=l.applied_by_staff_id
                               AND l.applied_on>='#{@from_date.strftime('%Y-%m-%d')}' AND l.applied_on<='#{@to_date.strftime('%Y-%m-%d')}'
                               AND l.deleted_at IS NULL AND l.client_id=cl.id AND cl.deleted_at IS NULL AND cl.center_id=c.id
                               GROUP BY st.id
                              })
  end
end

    # center_data = repository.adapter.query(%Q{
    #                            SELECT st.id manager_id, SUM(l.amount) avg
    #                            FROM  centers c, clients cl, loans l, staff_members st
    #                            WHERE  st.id=l.applied_by_staff_id AND l.disbursal_date IS NOT NULL
    #                            AND l.disbursal_date>='#{@from_date.strftime('%Y-%m-%d')}' AND l.disbursal_date<='#{@to_date.strftime('%Y-%m-%d')}'
    #                            AND l.deleted_at IS NULL AND l.client_id=cl.id AND cl.deleted_at IS NULL AND cl.center_id=c.id
    #                            GROUP BY st.id, c.id
    #                          }).group_by{|x| x.manager_id}.map{|k,v| {k => v.map{|x| x.avg.to_i}}}.inject({}){|s,x| s+=x}

    # @branch.each{|branch|
    #   StaffMember.all.each{|st|
    #     data[branch][manager] = if manager_data.key?(manager.id)
    #                               [manager_data[manager.id].center_count, manager_data[manager.id].client_count, 
    #                                applied_data[manager.id], approval_data[manager.id], manager_data[manager.id].amount, 
    #                                manager_data[manager.id].lavg, center_data[manager.id].inject(:+)/center_data[manager.id].length
    #                               ]
    #                             end
    #   }
    # }
