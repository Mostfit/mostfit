class ReportFormat
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  property :keys, CommaSeparatedList

end
