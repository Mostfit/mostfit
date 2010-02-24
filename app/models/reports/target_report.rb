class TargetReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id
  
  def initialize(params, dates)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today-7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today + 14
    @name   = "Report from #{@from_date} to #{@to_date}"
    @branch = Branch.get(params[:branch_id]) if params and params[:branch_id] and not params[:branch_id].blank?
    @center = Center.get(params[:center_id]) if params and params[:center_id] and not params[:center_id].blank?
    @staff_member = StaffMember.get(params[:staff_member_id]) if params and params[:staff_member_id] and not params[:staff_member_id].blank?
  end
  
  def name
    "Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Target vs Performance report"
  end

  def generate
    if @branch
      Target.all(:deadline.gte => from_date, :deadline.lte => to_date, :attached_to => :branch, :attached_id => @branch.id, :order => [:deadline])
    elsif @center
      Target.all(:deadline.gte => from_date, :deadline.lte => to_date, :attached_to => :center, :attached_id => @center.id, :order => [:deadline])
     elsif @staff_member
      Target.all(:deadline.gte => from_date, :deadline.lte => to_date, :attached_to => :staff_member, :attached_id => @staff_member.id, :order => [:deadline])
    else
      Target.all(:deadline.gte => from_date, :deadline.lte => to_date, :order => [:deadline])
    end
  end
end
