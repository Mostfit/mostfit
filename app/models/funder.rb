class Funder
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String, :length => 50, :nullable => false, :index => true

  has n, :funding_lines
  

  def self.catalog
    result = {}
    funder_names = {}
    Funder.all(:fields => [:id, :name]).each { |f| funder_names[f.id] = f.name }
    FundingLine.all(:fields => [:id, :amount, :interest_rate, :funder_id]).each do |funding_line|
      funder = funder_names[funding_line.funder_id]
      result[funder] ||= {}
      result[funder][funding_line.id] = "Rs. #{funding_line.amount} @ #{funding_line.interest_rate}%"
    end
    result
  end

  def completed_lines(date = Date.today)
    funding_lines.count(:conditions => ['last_payment_date < ?', date])
  end
  def active_lines(date = Date.today)
    funding_lines.count(:conditions => ['disbursal_date <= ? AND last_payment_date <= ?', date, date])
  end
  def total_lines(date = Date.today)
    funding_lines.count(:conditions => ['disbursal_date >= ?', date])
  end
end
