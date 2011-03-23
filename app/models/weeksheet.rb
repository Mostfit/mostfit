class Weeksheet
  attr_accessor :date
  attr_accessor :center_id
  attr_accessor :center_name
  attr_accessor :center_meeting_time
  attr_accessor :group_name
  attr_accessor :client_id
  attr_accessor :client_name
  attr_accessor :loan_id
  attr_accessor :loan_amount
  attr_accessor :disbursal_date
  attr_accessor :outstanding
  attr_accessor :principal
  attr_accessor :interest
  attr_accessor :total_due
  attr_accessor :fee
  attr_accessor :installment_number

  #Get weeksheet of center 
  def self.get_center_sheet(center, date)
    collection_of_weeksheet = []
    clients = center.clients
    loans = center.loans

    histories = LoanHistory.all(:loan_id => loans.map{|x| x.id}, :date => date)
    fees_applicable = Fee.due(loans.map{|x| x.id})
    clients.group_by{|x| x.client_group}.sort_by{|x| x[0] ? x[0].name : "none"}.each do |group, clients_grouped|
      clients_grouped.sort_by{|x| x.name}.each do |client|
        loans.find_all{|l| l.client_id == client.id and l.disbursal_date}.each do |loan|	    
          lh = histories.find_all{|x| x.loan_id==loan.id}.sort_by{|x| x.created_at}[-1]
          next if not lh
          next if LOANS_NOT_PAYABLE.include? lh.status
          fee = fees_applicable[loan.id] ? fees_applicable[loan.id].due : 0          

          weeksheet = Weeksheet.new
          weeksheet.date = date
          weeksheet.center_meeting_time = "#{center.meeting_time_hours}:#{'%02d' % center.meeting_time_minutes}"
          weeksheet.center_id = center.id
          weeksheet.center_name = center.name
          weeksheet.group_name = group ? group.name : "No group"
          weeksheet.client_id = client.name 
          weeksheet.client_name = client.name
          weeksheet.loan_id = loan.id
          weeksheet.loan_amount = loan.amount.to_currency
          weeksheet.disbursal_date =  loan.disbursal_date.to_s
          weeksheet.outstanding = (lh ? lh.actual_outstanding_principal : 0)
          weeksheet.principal = [(lh ? lh.principal_due : 0), 0].max
          weeksheet.interest = [(lh ? lh.interest_due : 0), 0].max
          weeksheet.total_due = [(lh ? (fee+lh.principal_due+lh.interest_due): 0), 0].max
          weeksheet.fee = fee.to_currency
          weeksheet.installment_number = loan.number_of_installments_before(date)

          collection_of_weeksheet << weeksheet	      
        end
      end
    end
    return collection_of_weeksheet
  end
end
