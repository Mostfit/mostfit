class JournalType 

  include DataMapper::Resource

  property :id,         Serial
  property :name,       String, :default => "Payment"  
  property :created_at, DateTime
  has n, :journal

  def display
    if self.name.downcase.to_sym == :payment 
      "<span class='pink'> #{self.name} </span>"
    elsif self.name.downcase.to_sym == :receipt
      "<span class='green'> #{self.name} </span>"
    else
      "<span class='blue'> #{self.name} </span>"
    end
  end

end
  
# if JournalType.all.empty?
#   DEFAULT_JOURNAL_TYPES.each do |x|
#     JournalType.create(:name => x)
#   end

      

