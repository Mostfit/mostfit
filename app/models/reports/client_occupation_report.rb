class ClientOccupationReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today  
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end
  
  def name
    "Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Client occupation report"
  end
  
  def generate
    repository.adapter.query("select count(*) clients, o.name occupation, count(l.id) loans, sum(l.amount) amount from clients LEFT OUTER JOIN loans l ON l.id=clients.id LEFT OUTER JOIN occupations o ON clients.occupation_id=o.id WHERE clients.id IN (#{Client.all(:id => @center.map{|x| x.id}).map{|x| x.id}.join(',')}) GROUP BY clients.occupation_id")
  end
end
