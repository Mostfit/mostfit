class OfflinePayments < Report
  attr_accessor :from_date, :to_date, :staff_member_id
  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today    
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def name
    "Offline Payments"
  end

  def self.name
    "Offline Payments"
  end

  def generate
    data = []
    hash = {:received_on.gte => from_date, :received_on.lte => to_date}
    hash[:received_by_staff_id] = staff_member_id if staff_member_id
    Payment.all(hash).each do |payment|
      data.push([payment.received_on, payment.id, payment.amount, payment.type, payment.loan_id, payment.client_id, payment.desktop_id, payment.origin, payment.received_by_staff_id])
    end
    return data
  end
end
