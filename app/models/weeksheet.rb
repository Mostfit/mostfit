class Weeksheet
  include DataMapper::Resource
  DAYS = [:none, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

  property :id, Serial
  property :date, Date
  property :staff_member_id, Integer
  property :center_id, Integer
  property :meeting_day,          Enum.send('[]', *DAYS), :nullable => false, :default => :none, :index => true
  property :meeting_time_hours,   Integer, :length => 2, :index => true
  property :meeting_time_minutes, Integer, :length => 2, :index => true

  has n, :weeksheet_rows
  belongs_to :staff_member
  belongs_to :center

  #Get weeksheet of center 
  def self.get_center_weeksheet(center, date, option = nil)
    if option == "data"
      weeksheet = Weeksheet.first(:center_id => center.id, :date => date)
      if weeksheet.blank?
        return Weeksheet.generate_weeksheet(center, date, option) 
      else
        return weeksheet.weeksheet_rows
      end
    else
     return Weeksheet.generate_weeksheet(center, date, option)    
    end
  end

  private
  def self.generate_weeksheet(center, date, option)
    collection_of_weeksheet = []
    clients = center.clients
    loans = center.loans
    
    weeksheet = Weeksheet.new
    weeksheet.staff_member_id = center.manager.id
    weeksheet.date = date
    weeksheet.center_id = center.id
    weeksheet.meeting_day = center.meeting_day?(date)? center.meeting_day : nil
    weeksheet.meeting_time_hours  = center.meeting_day?(date) ? center.meeting_time_hours : ""
    weeksheet.meeting_time_minutes = center.meeting_day?(date) ? center.meeting_time_minutes : ""
    #save weeksheet if request for database
    weeksheet.save! if option == "data"

    histories = LoanHistory.all(:loan_id => loans.map{|x| x.id}, :date => date)
    #TODO: temporary fix for fees
    #fees_applicable = Fee.due(loans.map{|x| x.id})
    clients.group_by{|x| x.client_group}.sort_by{|x| x[0] ? x[0].name : "none"}.each do |group, clients_grouped|
      clients_grouped.sort_by{|x| x.name}.each do |client|
        loan_row_count = 0
        loans.find_all{|l| l.client_id == client.id and l.disbursal_date}.each do |loan|	    
          lh = histories.find_all{|x| x.loan_id==loan.id}.sort_by{|x| x.created_at}[-1]
          next if not lh
          next if LOANS_NOT_PAYABLE.include? lh.status
          loan_row_count += 1
          #TODO: temporary fix for fees
          fee = 0#fees_applicable[loan.id] ? fees_applicable[loan.id].due : 0          
          weeksheet_row = weeksheet.weeksheet_rows.new 
   
          weeksheet_row.client_group_name = group ? group.name : "No group"
          weeksheet_row.client_group_id = group ? group.id : nil
          weeksheet_row.client_id = client.id
          weeksheet_row.client_name = client.name
          weeksheet_row.loan_id = loan.id
          weeksheet_row.loan_amount = loan.amount
          weeksheet_row.disbursal_date =  loan.disbursal_date.to_s
          weeksheet_row.outstanding = (lh ? lh.actual_outstanding_principal : 0)
          weeksheet_row.principal = [(lh ? lh.principal_due : 0), 0].max
          weeksheet_row.interest = [(lh ? lh.interest_due : 0), 0].max
          weeksheet_row.fees = fee
          weeksheet_row.installment = loan.number_of_installments_before(date)
          
          #save weeksheet row if request for database
          weeksheet_row.save! if option == "data"
          collection_of_weeksheet << weeksheet_row
        end
        if loan_row_count == 0
          weeksheet_row = weeksheet.weeksheet_rows.new 

          weeksheet_row.client_group_name = group ? group.name : "No group"
          weeksheet_row.client_group_id = group ? group.id : nil
          weeksheet_row.client_id = client.id
          weeksheet_row.client_name = client.name
          weeksheet_row.loan_id = nil
          weeksheet_row.loan_amount = 0
          weeksheet_row.disbursal_date =  nil
          weeksheet_row.outstanding = 0
          weeksheet_row.principal = 0
          weeksheet_row.interest = 0
          weeksheet_row.fees = 0
          weeksheet_row.installment = 0

          #save weeksheet row if request for database
          weeksheet_row.save if option == "data"
          collection_of_weeksheet << weeksheet_row	      
        end
      end
    end
    return collection_of_weeksheet
  end
end
