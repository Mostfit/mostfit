class Reports < Application
  include DateParser
  Types = [
           DailyReport, ConsolidatedReport, GroupConsolidatedReport, StaffConsolidatedReport, QuarterConsolidatedReport, TransactionLedger, ProjectedReport,
           LoanSanctionRegister, LoanDisbursementRegister, ScheduledDisbursementRegister, LateDisbursalsReport, LoanSizePerManagerReport, ClaimReport, 
           TargetReport, LoanPurposeReport, ClientOccupationReport, DelinquentLoanReport, ParByCenterReport, ClientAbsenteeismReport, 
           GeneralLedgerReport, TrialBalanceReport
          ]
  layout :determine_layout 

  # provides :xml, :yaml, :js
  def index
    @reports = Report.all
    display @reports
  end

  def show(report_type, id)
    provides :pdf
    report_type = params[:report_type] if report_type == "show" and params.key?(:report_type)
    klass = Kernel.const_get(report_type)
    @report = Report.get(id) if id
    class_key  =  klass.to_s.snake_case.to_sym
    dates = get_dates(class_key)

    if @report
      display @report
    elsif Reports::Types.include?(klass)
      #Generating report
      @report   = klass.new(params[class_key], dates, session.user)
      if not params[:submit]
        render :form
      elsif klass == TransactionLedger
        @groups, @centers, @branches, @payments, @clients = @report.generate
        display [@groups, @centers, @branches, @payments, @clients]
      elsif [LoanSanctionRegister].include?(klass)
        @groups, @centers, @branches, @loans, @loan_products = @report.generate
        display [@groups, @centers, @branches, @loans, @loan_products]
      else        
        case @report.method(:generate).arity
        when 0
          @data = @report.generate
        when 1
          @data = @report.generate(params)
        end
        display @data
      end
    elsif id.nil?
      @reports = klass.all(:order => [:start_date.desc])
      if klass==DuplicateClientsReport and (DuplicateClientsReport.count==0 or (Date.today - DuplicateClientsReport.all.aggregate(:created_at).max).to_i>6)
        DuplicateClientsReport.new.generate
      end
      display @reports
    elsif id and params[:format] == "pdf"
      send_data(@report.get_pdf.generate, :filename => 'report.pdf')
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
  def get_dates(class_key)
    dates = {}
    if  params[class_key]
      dates[:date]      = get_date(params[class_key], :date) if params[class_key][:date]
      dates[:from_date] = get_date(params[class_key], :from_date) if params[class_key][:from_date]
      dates[:to_date]   = get_date(params[class_key], :to_date) if params[class_key][:to_date]
    end
    dates
  end

  def get_date(params, col)
    if params and params.key?(col)
      date_hash = params[col]
      return Date.parse(date_hash)
    end
  end
  
  def determine_layout
    return "printer" if params[:layout] and params[:layout]=="printer"
  end
end # Reports
