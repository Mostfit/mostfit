class Reports < Application
  Types = [DailyReport, ConsolidatedReport, TransactionLedger, ProjectedReport, LoanDisbursementRegister, TargetReport]
  # provides :xml, :yaml, :js
  def index
    @reports = Report.all
    display @reports
  end

  def show(report_type, id)
    provides :pdf
    klass = Kernel.const_get(report_type)
    @report = Report.get(id) if id
    class_key  =  klass.to_s.snake_case.to_sym

    dates = {}
    if  params[class_key]
      dates[:date]      = get_date(params[class_key], :date) if params[class_key][:date]
      dates[:from_date] = get_date(params[class_key], :from_date) if params[class_key][:from_date]
      dates[:to_date]   = get_date(params[class_key], :to_date) if params[class_key][:to_date]
    end

    if Reports::Types.include?(klass)
      #Generating report
      @report   = klass.new(params[class_key], dates)
      if klass==TransactionLedger
        @groups, @centers, @branches, @payments, @clients = @report.generate
        display [@groups, @centers, @branches, @payments, @clients]
      elsif klass==LoanDisbursementRegister
        @groups, @centers, @branches, @loans, @loan_products = @report.generate
        display [@groups, @centers, @branches, @loans, @loan_products]
      elsif klass==TargetReport
        @targets = @report.generate
        display [@targets]
      else
        @groups, @centers, @branches = @report.generate
        display [@groups, @centers, @branches]
      end
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
    end
  end
end # Reports
