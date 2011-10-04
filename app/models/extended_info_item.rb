
class ExtendedInfoItem
  include DataMapper::Resource
  
  property :id,          Serial
  property :item_type,   String
  property :item_id,     Integer
  property :item_value,  String
  property :parent_guid, String
  
  belongs_to :transaction_log, :parent_key => [:txn_log_guid], :child_key => [:parent_guid]
end
