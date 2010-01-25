class Holiday
  include DataMapper::Resource
  after :save, :update_loan_history
  after :destroy, :update_loan_history
  property :id, Serial

  property :name, String, :length => 50, :nullable => false
  property :date, Date, :nullable => false, :unique => true
  property :shift_meeting, Enum[:before, :after]
  
  def update_loan_history
    $holidays = Holiday.all.map{|h| [h.date, h]}.to_hash
    LoanHistory.all(:date => date).loans.each{|l| l.update_history}
  end
end
