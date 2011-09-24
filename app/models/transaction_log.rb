class TransactionLog
  include DataMapper::Resource

  UPDATE_TYPES = [:create, :delete]
  TRANSACTION_TYPE = [:receipt]
  NATURE_OF_TRANSACTION = [:principal_received, :interest_received, :fees_received]
  PAYOR_TYPES = [:client]
  PAYEE_TYPES = [:staff_member]
  LOCATION_TYPES = [:center]

  CURRENCY = [:INR, :KES]
  
  property :id,                    Serial
  property :txn_log_guid,          String, :default => lambda{ |obj, p| UUID.generate }
  property :txn_guid,              String
  property :parent_org_guid,       String
  property :parent_domain_guid,    String         

  property :update_type,           Enum.send('[]', *UPDATE_TYPES)
  property :txn_type,              Enum.send('[]', *TRANSACTION_TYPE)
  property :nature_of_transaction, Enum.send('[]', *NATURE_OF_TRANSACTION)
  property :sub_type_id,           Integer
  property :sub_type_name,         String
  
  property :amount,           Float
  property :currency,         Enum.send('[]', *CURRENCY)
  property :effective_date,   Date
  property :record_date,      DateTime
  property :updated_at_time,  DateTime
  property :verified_at_time, DateTime
  property :deleted_at_time,  DateTime
  
  property :paid_by_type,     Enum.send('[]', *PAYOR_TYPES) 
  property :paid_by_id,       Integer
  property :paid_by_name,     String
  
  property :received_by_type, Enum.send('[]', *PAYEE_TYPES)
  property :received_by_id,   Integer
  property :received_by_name, String
  
  property :transacted_at_type,  Enum.send('[]', *LOCATION_TYPES)
  property :transacted_at_id,    Integer
  property :transacted_at_name,  String

  has n, :extended_info_items, :model => 'ExtendedInfoItem', :parent_key => [:txn_log_guid], :child_key => [:parent_guid]

  def payment2transaction_log(payment)
    transaction_attributes = {}
    client_name = payment.client ? payment.client.name : nil
    center = payment.client && payment.client.center ? payment.client.center : nil
    center_id = center ? center.id : nil
    center_name = center ? center.name : nil
    
    staff_member = payment.received_by_staff_id ? StaffMember.get(payment.received_by_staff_id) : nil
    staff_member_name = staff_member ? staff_member.name : nil
    fee_name = payment.fee ? payment.fee.name : nil
    
    extended_info = payment.extended_info

    payment_attributes = payment.attributes
    mapping ||= { 
      :guid                   => :txn_guid,
      :parent_org_guid        => :parent_org_guid,
      :parent_domain_guid     => :parent_domain_guid   ,
      :type                   => :nature_of_transaction,
      :fee_id                 => :sub_type_id          ,
      :amount                 => :amount               ,
      :received_on            => :effective_date       ,
      :created_at             => :record_date          ,
      :deleted_at             => :deleted_at_time      ,
      :client_id              => :paid_by_id           ,
      #'client.name'           => :paid_by_name         ,
      :received_by_staff_id   => :received_by_id       ,
      #'staff_member.name'     => :received_by_name     ,
      #'client.center_id'      => :transacted_at_id     ,
      #'client.center.name'    => :transacted_at_name   
    }

    mapping.keys.each{|x| transaction_attributes[mapping[x]] = payment_attributes[x]}
    self.attributes = transaction_attributes
    self.nature_of_transaction = "#{payment.type}_received".to_sym    
    self.sub_type_name = fee_name
    self.extended_info_items = payment.extended_info
    self.txn_type = :receipt
    self.sub_type_name = fee_name
    self.currency = :INR
    self.updated_at_time = nil
    self.verified_at_time = nil
    self.paid_by_type = :client
    self.paid_by_name = client_name
    self.received_by_type = :staff_member
    self.received_by_name = staff_member_name
    self.transacted_at_type = :center
    self.transacted_at_id = center_id
    self.transacted_at_name = center_name
    self.extended_info_items = extended_info  
    return transaction_attributes
  end

  def to_xml(tl)
    block_of_code = Proc.new do
      tl.transaction_log{
        tl.txn_log_guid          self.txn_log_guid      
        tl.txn_guid              self.txn_guid
        tl.update_type           self.update_type.to_s
        tl.txn_type              self.txn_type.to_s         
        tl.nature_of_transaction self.nature_of_transaction.to_s
        tl.sub_type_id           self.sub_type_id       
        tl.sub_type_name         self.sub_type_name     
        tl.amount                self.amount          
        tl.currency              self.currency.to_s        
        tl.effective_date        self.effective_date  
        tl.record_date           self.record_date     
        tl.updated_at_time       self.updated_at_time 
        tl.verified_at_time      self.verified_at_time 
        tl.deleted_at_time       self.deleted_at_time 
        tl.paid_by_type          self.paid_by_type.to_s    
        tl.paid_by_id            self.paid_by_id      
        tl.paid_by_name          self.paid_by_name    
        tl.received_by_type      self.received_by_type.to_s
        tl.received_by_id        self.received_by_id  
        tl.received_by_name      self.received_by_name
        tl.transacted_at_type    self.transacted_at_type.to_s  
        tl.transacted_at_id      self.transacted_at_id    
        tl.transacted_at_name    self.transacted_at_name
        tl.parent_org_guid       self.parent_org_guid
        tl.parent_domain_guid    self.parent_domain_guid
        if self.extended_info_items
          tl.extended_info_items{
            self.extended_info_items.each do |e|
              tl.extended_info_item{
                tl.item_type   e.item_type
                tl.item_id     e.item_id
                tl.item_value  e.item_value
                tl.parent_guid e.parent_guid
              }
            end
          }
        end
      }
    end
    return block_of_code
  end

end
