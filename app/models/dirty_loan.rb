class DirtyLoan
  include DataMapper::Resource
  @@poke_thread = false

  property :id, Serial
  property :loan_id, Integer, :index => true, :nullable => false
  property :created_at, DateTime, :index => true, :nullable => false, :default => Time.now
  property :cleaning_started, DateTime, :index => true, :nullable => true
  property :cleaned_at, DateTime, :index => true, :nullable => true

  belongs_to :loan

  def self.add(loan)
    if loan.is_a? Loan
      dirty = DirtyLoan.first_or_create(:loan => loan, :cleaned_at => nil)      
    elsif loan.is_a? Integer
      dirty = DirtyLoan.first_or_create(:loan_id => loan, :cleaned_at => nil)      
    end
    @@poke_thread = true
  end

  def self.clear(id=nil)
    hash = {}
    hash[:cleaned_at] = nil
    hash[:id] = id if id
    DirtyLoan.all(hash).each{|dl|
      if not dl.cleaning_started or (Time.now.to_time - dl.cleaning_started.to_time > 14400)
        dl.cleaning_started = Time.now
        dl.save
      end
      begin
        dl.loan.update_history(true)
        dl.cleaned_at = Time.now
        dl.save
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    }
    @@poke_thread = false if pending.length ==  0
    return true
  end

  def self.pending
    DirtyLoan.all(:cleaned_at => nil)
  end

  def self.start_thread
    cleaner_interval = Kernel.const_defined?("CLEANER_INTERVAL") ? CLEANER_INTERVAL : 300
    if true
      Thread.new{
        counter = 0
        while true
          if @@poke_thread or counter == cleaner_interval
            self.clear
            counter = 0
          end
          sleep 30
          counter += 10
        end        
      }
      return true
    else
      return false
    end
  end
end
