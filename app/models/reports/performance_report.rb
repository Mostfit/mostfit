class PerformanceReport < Report
  include Reporting::OrganizationReports

  def initialize(start_date)
    self.start_date = (start_date.is_a? Date) ? start_date : Date.parse(start_date)
    self.end_date   = self.start_date + (Date.new(start_date.year,12,31).to_date<<(12-start_date.month)).day
    @name = "Performance report upto #{end_date}"
  end

  def name
    "Performance report upto #{end_date}"
  end

  def to_str
    "#{start_date} - #{end_date}"
  end

  def calc
    @report = []
    t0 = Time.now
    puts "generating..."
    @report[0] = {'Branches' => branch_count(end_date)}
    @report[1] = {'Centers' => centers_count(end_date)}
    @report[2] = {"CMs"  => cms_count(end_date)}
    @report[3] = {"Clients" => clients_count(end_date)}
    @report[4] = {"Borrowers" => borrowers(end_date)}
    @report[5] = {"Disbursed" => disbursed(end_date, "sum")}
    @report[6] = {"Net portfolio" => net_portfolio(end_date)}
    self.raw = @report
    self.report = Marshal.dump(@report)
    self.generation_time = Time.now - t0
    self.save
  end
end
