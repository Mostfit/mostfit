class Report
  include DataMapper::Resource

  attr_accessor :raw
  property :id, Serial
  property :start_date, Date
  property :end_date, Date
  property :report, Yaml, :length => 20000
  property :dirty, Boolean
  property :report_type, Discriminator
  property :created_at, DateTime
  property :generation_time, Integer

  def name
    "#{report_type}: #{start_date} - #{end_date}"
  end

  def get_pdf
    pdf = PDF::HTMLDoc.new
    pdf.set_option :bodycolor, :white
    pdf.set_option :toc, false
    pdf.set_option :portrait, true
    pdf.set_option :links, true
    pdf.set_option :webpage, true
    pdf.set_option :left, '2cm'
    pdf.set_option :right, '2cm'
    pdf.set_option :header, "Header here!"
    f = File.read("app/views/reports/_#{name.snake_case.gsub(" ","_")}.pdf.haml")
    report = Haml::Engine.new(f).render(Object.new, :report => self)
    pdf << report
    pdf.footer ".t."
    pdf
  end

  def get_parameters(params)
    @branch = if params and params[:branch_id] and not params[:branch_id].blank?
                Branch.all(:id => params[:branch_id])
              else
                Branch.all(:order => [:name])
              end    
    if params and params[:center_id] and not params[:center_id].blank?
      @center = Center.all(:id => params[:center_id])
    elsif params and params[:staff_member_id] and not params[:staff_member_id].blank?
      @center = StaffMember.get(params[:staff_member_id]).centers
    else
      @center  = @branch.collect{|b| b.centers}.flatten
    end    
  end
end
