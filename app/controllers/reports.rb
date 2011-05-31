class Reports < Application
  include DateParser
  Types = {
    :periodic     => [DailyReport, WeeklyReport], 
    :consolidated => [DailyTransactionSummary, ConsolidatedReport, GroupConsolidatedReport, StaffConsolidatedReport, QuarterConsolidatedReport, AggregateConsolidatedReport], 
    :registers    => [TransactionLedger, LoanSanctionRegister, LoanDisbursementRegister, ScheduledDisbursementRegister, ClaimReport, InsuranceRegister, PortfolioAllocationReport], 
    :targets_and_projections  => [ProjectedReport, TargetReport, StaffTargetReport, MonthlyTargetReport, IncentiveReport],
    :statistics   => [LoanSizePerManagerReport, LoanPurposeReport, ClientOccupationReport, ClosedLoanReport], 
    :exceptions   => [RepaymentOverdue, LateDisbursalsReport, DelinquentLoanReport, ParByCenterReport, ParByStaffReport, ParByLoanAgeingReport, ClientAttendanceReport, DuplicateClientsReport, NonDisbursedClientsAfterGroupRecognitionTest],
    :accounting   => [GeneralLedgerReport, TrialBalanceReport, DayBook, CashBook, BankBook, IncomeStatement, BalanceSheet]
  }
  Order = [:periodic, :consolidated, :registers, :targets_and_projections, :statistics, :exceptions, :accounting]
  layout :determine_layout
  before :set_staff_and_user, :only => [:index, :show]
  
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
    elsif Reports::Types.values.flatten.include?(klass) and not klass==WeeklyReport and not klass==DuplicateClientsReport and not klass==IncentiveReport
      #Generating report
      @report   = klass.new(params[class_key], dates, session.user)
      if not params[:submit]
        render :form
      else
        if @report.valid?
          case @report.method(:generate).arity
          when 0
            @data = @report.generate
          when 1
            @data = @report.generate(params)
          end
          display @data
        else
          params.delete(:submit)
          message[:error] = "Report cannot be generated"          
          render :form
        end
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
    if params and params.key?(col) and params[col] and not params[col].blank?
      date_hash = params[col]
      return Date.strptime(date_hash, Mfi.first.date_format || ('%Y-%m-%d'))
    end
  end
    
  def set_staff_and_user
    @user = session.user
    @staff_member = @user.staff_member
  end
  
end # Reports
