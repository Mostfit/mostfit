class LoanUtilization
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :length => (3..25), :nullable => false

end
