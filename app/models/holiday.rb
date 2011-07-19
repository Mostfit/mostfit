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
    repository.adapter.execute("update loan_history set date='#{date.holiday_bump.strftime('%Y-%m-%d')}' where date='#{date.strftime('%Y-%m-%d')}'")
    holiday = [date.day, date.month, date.strftime('%y')]
    if $holidays_list.include?(holiday)
      $holidays_list.delete(holiday)
    else
      $holidays_list << holiday 
    end
  end
end
