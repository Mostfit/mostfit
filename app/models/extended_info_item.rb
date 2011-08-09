class ExtendedInfoItem
  include DataMapper::Resource
  
  property :id,         Serial
  property :item_type,  String
  property :item_id,    Integer
  property :item_value, String
  
  belongs_to :transaction_log
end
