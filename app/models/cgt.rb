class Cgt
  include DataMapper::Resource
  
  CGT_STATUSES = ['Scheduled','Completed','Not Conducted']
  
  property :id, Serial
  property :date, Date, :unique => :client_group
  property :day_number, Integer, :nullable => false, :unique => :client_group
  property :status, Enum.send('[]',*CGT_STATUSES), :default => 'Scheduled'

  belongs_to :client_group

  def self.statuses
    CGT_STATUSES
  end

end
