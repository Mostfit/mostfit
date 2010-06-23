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

  def get_parameters(params, user=nil)
    st = user.staff_member
    @branch = if user and st
                [st.centers.branches, st.branches].flatten
              else
                (params and params[:branch_id] and not params[:branch_id].blank?) ? Branch.all(:id => params[:branch_id]) : Branch.all(:order => [:name])
              end
    @center = if user and st and (not params or not params[:staff_member_id] or params[:staff_member_id].blank?)
                [st.centers, st.branches.centers].flatten
              elsif params and params[:center_id] and not params[:center_id].blank?
                Center.all(:id => params[:center_id])
              elsif params and params[:staff_member_id] and not params[:staff_member_id].blank?
                StaffMember.get(params[:staff_member_id]).centers
              else
                @branch.collect{|b| b.centers}.flatten
              end    
    @loan_product_id = if params and params[:loan_product_id] and params[:loan_product_id].to_i>0
                      params[:loan_product_id].to_i
                    else
                      nil
                    end
    [:late_by_days, :absent_more_than].each{|key|
      instance_variable_set("@#{key}", if params and params[key] and params[key].to_i>0
                                         params[key].to_i
                                       else
                                         nil
                                       end)
    }
  end
end
