class TargetReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id
  
  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today-7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today + 14
    @name      = "Report from #{@from_date} to #{@to_date}"
    @branch_id = params ? params[:branch_id] : nil
    @center_id = params ? params[:center_id] : nil
    @staff_member_id = params ? params[:staff_member_id] : nil
    get_parameters(params, user)
  end
  
  def name
    "Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Target vs Performance report"
  end

  def generate
    targets = []
    hash = if @branch_id and @branch_id.to_i > 0 
             {:attached_to => :branch, :attached_id => @branch.map{|x| x.id}}
           elsif @center_id and @center_id.to_i > 0 
             {:attached_to => :center, :attached_id => @center.map{|x| x.id}}
           elsif @staff_member_id and @staff_member_id.to_i > 0 
             {:attached_to => :staff_member, :attached_id => @staff_member.map{|x| x.id}}
           else
             {}
           end
    params  = {:deadline.gte => from_date, :deadline.lte => to_date, :order => [:deadline]}
    params += hash    
    Target.all(params)
  end
end
