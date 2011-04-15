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
    repository.adapter.query(%Q{SELECT o.name occupation, count(clients.id) clients, count(loans.id) loans, SUM(loans.amount) amount
                                FROM loans, clients
                                LEFT OUTER JOIN occupations o ON o.id=clients.occupation_id
                                WHERE clients.id=loans.client_id AND clients.id IN (SELECT id FROM clients 
                                                                                    WHERE date_joined BETWEEN '#{@from_date.strftime('%Y-%m-%d')}' 
                                                                                          AND '#{@to_date.strftime('%Y-%m-%d')}'
                                                                                          AND clients.center_id in (#{@center.map{|c| c.id}.join(', ')}))
                                      AND loans.deleted_at is NULL AND loans.disbursal_date is NOT NULL
                                GROUP BY clients.occupation_id;})
  end
end
