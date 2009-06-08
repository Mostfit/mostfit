class Reports < Application
  # provides :xml, :yaml, :js

  def index
    @reports = Report.all
    display @reports
  end

  def show(id)
    provides :pdf
    @report = Report.get(id)
    raise NotFound unless @report
    if params[:format] == "pdf"
      pdf = PDF::HTMLDoc.new
      pdf.set_option :bodycolor, :white
      pdf.set_option :toc, false
      pdf.set_option :portrait, true
      pdf.set_option :links, true
      pdf.set_option :webpage, true
      pdf.set_option :left, '2cm'
      pdf.set_option :right, '2cm'
      pdf.set_option :header, "Header here!"
      debugger
      f = File.read("app/views/reports/_#{@report.name.snake_case.gsub(" ","_")}.html.haml")
      report = Haml::Engine.new(f).render
      pdf << report
      pdf.footer ".t."
      send_data pdf.generate, :filename => 'report.pdf'
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
