class IncentiveReport < Report
#  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def self.name
    "Incentive Report "
  end

  def generate
       
  
    
   # repository.adapter.query("select sm.name staff,sm.creation_date doj,count(cl.id) abc, c.id center from clients cl, centers c, staff_members sm where cl.center_id = c.id and c.manager_staff_id = sm.id group by sm.id")
 
   repository.adapter.query("select sm.name staff,sm.creation_date doj,count(cl.id) tot_client, a.name area from clients cl, centers c, staff_members sm,branches b,areas a where cl.center_id = c.id and c.branch_id = b.id and b.area_id = a.id and c.manager_staff_id = sm.id group by sm.id")
  end
end
