class Funder
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String, :length => 50, :nullable => false

  has n, :funding_lines

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
