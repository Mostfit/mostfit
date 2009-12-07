class Reports < Application
  # provides :xml, :yaml, :js

  def index
    @reports = Report.all
    display @reports
  end

  def show(report_type, id)
    provides :pdf
    klass = Kernel.const_get(report_type)
    @report = Report.get(id) if id

    if klass==DailyReport
      #Generating daily report
      date = get_date(params[:daily_report], :date)
      @report = DailyReport.new(date)
      @groups, @centers, @branches = @report.generate(params)
      display [@groups, @centers, @branches]      
    elsif klass==TimeRangeReport
      #Generating time range report
      from_date = get_date(params[:time_range_report], :from_date)
      to_date   = get_date(params[:time_range_report], :to_date)
      @report   = TimeRangeReport.new(from_date==to_date ? from_date-7 : from_date, to_date)
      @groups, @centers, @branches = @report.generate(params)
      display [@groups, @centers, @branches]
    elsif id.nil?
      @reports = klass.all
      display @reports
    elsif id and params[:format] == "pdf"
      send_data(@report.get_pdf.generate, :filename => 'report.pdf')
    else
      display @report
    end
  end

  def new
    only_provides :html
    @report = Report.new
    display @report
  end

  def edit(id)
    only_provides :html
    @report = Report.get(id)
    raise NotFound unless @report
    display @report
  end

  def create(report)
    @report = Report.new(report)
    if @report.save
      redirect resource(:reports), :message => {:notice => "Report was successfully created"}
    else
      message[:error] = "Report failed to be created"
      render :new
    end
  end

  def update(id, report)
    @report = Report.get(id)
    raise NotFound unless @report
    if @report.update_attributes(report)
       redirect resource(@report)
    else
      display @report, :edit
    end
  end

  def destroy(id)
    @report = Report.get(id)
    raise NotFound unless @report
    if @report.destroy
      redirect resource(:reports)
    else
      raise InternalServerError
    end
  end

  private
  def get_date(params, col)
    if params and params.key?(col)
      date_hash = params[col]
      return Date.parse(date_hash[:year] + "-" + date_hash[:month] + "-" + date_hash[:day])
    else
      Date.today
    end
  end
end # Reports
