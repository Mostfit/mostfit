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
end
