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
      if params[:daily_report] and params[:daily_report][:date]
        date_hash = params[:daily_report][:date]
        date  =  Date.parse(date_hash[:year] + "-" + date_hash[:month] + "-" + date_hash[:day])
      else
        date  = Date.today
      end
      @report = DailyReport.new(date)
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

end # Reports
