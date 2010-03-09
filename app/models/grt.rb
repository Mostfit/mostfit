class Grt
  include DataMapper::Resource
  
  GRT_STATUSES = ['Passed','Failed','Not conducted']

  property :id, Serial
  property :date, Date, :nullable => false, :unique => :client_group
  property :status, Enum.send('[]', *GRT_STATUSES), :nullable => true, :default => 'Not conducted'

  belongs_to :client_group

  def self.statuses
    GRT_STATUSES
  end
end
