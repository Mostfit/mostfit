class Predicate
  include DataMapper::Resource
  
  property :id,             Serial
  property :rule_id,        Integer
  property :condition_type, Enum[:condition, :pre_condition]
  property :key,            String
  property :operator,       Enum[:equal, :not_equal, :less_than, :less_than_equal, :greater_than, :greater_than_equal]
  property :value,          String

  belongs_to :rule
  
end
