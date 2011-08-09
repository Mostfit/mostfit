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
  property :txn_id,                Integer
  property :txn_guid,              String
  property :txn_update_type,       Enum.send('[]', *UPDATE_TYPES)
  property :txn_type,              Enum.send('[]', *TRANSACTION_TYPE)
  property :nature_of_transaction, Enum.send('[]', *NATURE_OF_TRANSACTION)
  property :txn_sub_type_id,       Integer
  property :txn_sub_type_name,     String
  
  property :txn_amount,          Float
  property :txn_currency,        Enum.send('[]', *CURRENCY)
  property :txn_effective_date,  Date
  property :txn_record_date,     DateTime
  property :txn_updated_at_time, DateTime
  property :txn_verified_at_time, DateTime
  property :txn_deleted_at_time, DateTime
  
  property :txn_paid_by_type,     Enum.send('[]', *PAYOR_TYPES) 
  property :txn_paid_by_id,       Integer
  property :txn_paid_by_name,     String
  
  property :txn_received_by_type, Enum.send('[]', *PAYEE_TYPES)
  property :txn_received_by_id,   Integer
  property :txn_received_by_name, String
  
  property :txn_transacted_at_type,  Enum.send('[]', *LOCATION_TYPES)
  property :txn_transacted_at_id,    Integer
  property :txn_transacted_at_name,  String

  has n, :extended_info_items, :model => 'ExtendedInfoItem'
end
