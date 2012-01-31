class ReportFormats < Application
  # provides :xml, :yaml, :js

  def index
    @report_formats = ReportFormat.all
    display @report_formats
  end

  def show(id)
    @report_format = ReportFormat.get(id)
    raise NotFound unless @report_format
    display @report_format
  end

  def new
    only_provides :html
    @report_format = ReportFormat.new
    display @report_format
  end

  def edit(id)
    only_provides :html
    @report_format = ReportFormat.get(id)
    raise NotFound unless @report_format
    display @report_format
  end

  def create(report_format)
    @report_format = ReportFormat.new(report_format)
    if @report_format.save
      redirect resource(@report_format), :message => {:notice => "ReportFormat was successfully created"}
    else
      message[:error] = "ReportFormat failed to be created"
      render :new
    end
  end

  def update(id, report_format)
    @report_format = ReportFormat.get(id)
    raise NotFound unless @report_format
    if @report_format.update(report_format)
      redirect resource(@report_format)
    else
      display @report_format, :edit
    end
  end

  def destroy(id)
    @report_format = ReportFormat.get(id)
    raise NotFound unless @report_format
    if @report_format.destroy
      redirect resource(:report_formats)
    else
      raise InternalServerError
    end
  end

end # ReportFormats
