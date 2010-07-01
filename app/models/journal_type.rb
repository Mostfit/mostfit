class JournalType 
 # *VOUCHERS['Payment', 'Receipt', 'Journal']
  include DataMapper::Resource

  property :id,         Serial
  property :name,       String, :default => "Payment"  
  property :created_at, DateTime
  has n, :journal
  
  def self.create_journal_type
    voucher_types = ['Payment','Receipt','Journal']
    begin 
      if JournalType.all.empty?
        voucher_types.each do |x|
          journal_type = JournalType.new(:name => x)
          if journal_type.save
            Merb.logger.info("The initial Voucher  was created...")
          else
            Merb.logger.info("Conldn't create the Voucher .......")
            u.errors.each do |e|
              Merb.logger.info(e)
            end
          end
        end
      end
    rescue
      Merb.logger.info("Couldn't create the Voucher, Possibly unable to access the database.")
    end
  end
    
end

