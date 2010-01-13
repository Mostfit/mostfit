class Client
  include Paperclip::Resource
  include DateParser  # mixin for the hook "before :valid?, :parse_dates"
  include DataMapper::Resource

  before :valid?, :parse_dates
  before :valid?, :convert_blank_to_nil

  property :id,             Serial
  property :reference,      String, :length => 100, :nullable => false, :index => true
  property :name,           String, :length => 100, :nullable => false, :index => true
  property :spouse_name,    String, :length => 100
  property :date_of_birth,  Date,   :index => true
  property :address,        Text
  property :active,         Boolean, :default => true, :nullable => false, :index => true
  property :date_joined,    Date,    :index => true
  property :grt_pass_date,  Date,    :index => true, :nullable => true
  property :client_group_id,Integer, :index => true, :nullable => true
  property :center_id,      Integer, :index => true, :nullable => true
  property :created_at,     DateTime, :default => Time.now
  property :deleted_at,     ParanoidDateTime
  property :client_type,    Enum[:default], :default => :default
  property :created_by_user_id,  Integer, :nullable => false, :index => true
  property :verified_by_user_id, Integer, :nullable => true, :index => true

  property :account_number, String, :length => 20, :nullable => true
  property :type_of_account, Enum.send('[]', *['', 'savings', 'current', 'no_frill', 'fixed_deposit', 'loan', 'other'])
  property :bank_name,      String, :length => 20, :nullable => true
  property :branch,         String, :length => 20, :nullable => true
  property :join_holder,    String, :length => 20, :nullable => true
  property :client_type,    Enum[:default], :default => :default
  property :number_of_family_members, Integer, :length => 10, :nullable => true
  property :children_girls_under_5_years, Integer, :length => 10, :default => 0
  property :children_girls_5_to_15_years, Integer, :length => 10, :default => 0
  property :children_girls_over_5_years, Integer, :length => 10, :default => 0
  property :children_sons_under_5_years, Integer, :length => 10, :default => 0
  property :children_sons_5_to_15_years, Integer, :length => 10, :default => 0
  property :children_sons_over_5_years, Integer, :length => 10, :default => 0
  property :not_in_school_working_girls, Integer, :length => 10, :default => 0
  property :not_in_school_bonded_girls, Integer, :length => 10, :default => 0
  property :not_in_school_working_sons, Integer, :length => 10, :default => 0
  property :not_in_school_bonded_sons, Integer, :length => 10, :default => 0
  property :school_distance, Integer, :length => 10, :nullable => true
  property :phc_distance, Integer, :length => 10, :nullable => true
  property :member_literate, Enum.send('[]', *['', 'no', 'yes']), :default => '', :nullable => true
  property :husband_litrate, Enum.send('[]', *['', 'no', 'yes']), :default => '', :nullable => true
  property :other_productive_asset, String, :length => 30, :nullable => true
  property :income_regular, Enum.send('[]', *['', 'no', 'yes']), :default => '', :nullable => true
  property :client_migration, Enum.send('[]', *['', 'no', 'yes']), :default => '', :nullable => true
  property :pr_loan_amount, Integer, :length => 10, :nullable => true
  property :other_income, Integer, :length => 10, :nullable => true
  property :total_income, Integer, :length => 10, :nullable => true
  property :poverty_status, String, :length => 10, :nullable => true
  property :irrigated_land_own_fertile, Integer
  property :irrigated_land_leased_fertile, Integer
  property :irrigated_land_shared_fertile, Integer
  property :irrigated_land_own_semifertile, Integer
  property :irrigated_land_leased_semifertile, Integer
  property :irrigated_land_shared_semifertile, Integer
  property :irrigated_land_own_wasteland, Integer
  property :irrigated_land_leased_wasteland, Integer
  property :irrigated_land_shared_wasteland, Integer
  property :children_girls_under_5_years, Integer, :length => 10, :default => 0
  property :children_girls_5_to_15_years, Integer, :length => 10, :default => 0
  property :children_girls_over_5_years, Integer, :length => 10, :default => 0
  property :children_sons_under_5_years, Integer, :length => 10, :default => 0
  property :children_sons_5_to_15_years, Integer, :length => 10, :default => 0
  property :children_sons_over_5_years, Integer, :length => 10, :default => 0
  property :not_in_school_working_girls, Integer, :length => 10, :default => 0
  property :not_in_school_bonded_girls, Integer, :length => 10, :default => 0
  property :not_in_school_working_sons, Integer, :length => 10, :default => 0
  property :not_in_school_bonded_sons, Integer, :length => 10, :default => 0
  property :irrigated_land_own_fertile, Integer
  property :irrigated_land_leased_fertile, Integer
  property :irrigated_land_shared_fertile, Integer
  property :irrigated_land_own_semifertile, Integer
  property :irrigated_land_leased_semifertile, Integer
  property :irrigated_land_shared_semifertile, Integer
  property :irrigated_land_own_wasteland, Integer
  property :irrigated_land_leased_wasteland, Integer
  property :irrigated_land_shared_wasteland, Integer
  property :not_irrigated_land_own_fertile, Integer
  property :not_irrigated_land_leased_fertile, Integer
  property :not_irrigated_land_shared_fertile, Integer
  property :not_irrigated_land_own_semifertile, Integer
  property :not_irrigated_land_leased_semifertile, Integer
  property :not_irrigated_land_shared_semifertile, Integer
  property :not_irrigated_land_own_wasteland, Integer
  property :not_irrigated_land_leased_wasteland, Integer
  property :not_irrigated_land_shared_wasteland, Integer
  validates_length :number_of_family_members, :max => 20
  validates_length :school_distance, :max => 200
  validates_length :phc_distance, :max => 500

  has n, :payments

  validates_length :account_number, :max => 20

  belongs_to :created_by,  :child_key => [:created_by_user_id],   :model => 'User'
  belongs_to :verified_by, :child_key => [:verified_by_user_id],  :model => 'User'  

  has_attached_file :picture,
      :styles => {:medium => "300x300>", :thumb => "60x60#"},
      :url => "/uploads/:class/:id/:attachment/:style/:basename.:extension",
      :path => "#{Merb.root}/public/uploads/:class/:id/:attachment/:style/:basename.:extension",
      :default_url => "/images/no_photo.jpg"

  has_attached_file :application_form,
      :styles => {:medium => "300x300>", :thumb => "60x60#"},
      :url => "/uploads/:class/:id/:attachment/:style/:basename.:extension",
      :path => "#{Merb.root}/public/uploads/:class/:id/:attachment/:style/:basename.:extension"

  has n, :loans
  belongs_to :center
  belongs_to :client_group

  validates_length    :name, :min => 3
  validates_present   :center
  validates_present   :date_joined
  validates_is_unique :reference
  validates_attachment_thumbnails :picture
  
  def self.from_csv(row, headers)
    center_id       = row[headers[:center]] ? Center.first(:name => row[headers[:center]].strip).id : 0
    client_group_id = row[headers[:group_code]] ? ClientGroup.first(:code => row[headers[:group_code]].strip).id : nil
    grt_date        = row[headers[:grt_date]] ? Date.parse(row[headers[:grt_date]]) : nil
    obj             = new(:reference => row[headers[:reference]], :name => row[headers[:name]], :spouse_name => row[headers[:spouse_name]], 
                          :date_of_birth => Date.parse(row[headers[:date_of_birth]]), :address => row[headers[:address]], :date_joined => row[headers[:date_joined]],
                          :center_id => center_id, :grt_pass_date => grt_date,
                          :client_group_id => client_group_id)
    [obj.save, obj]
  end

  def self.search(q)
    if /^\d+$/.match(q)
      all(:conditions => {:id => q})
    else
      all(:conditions => ["reference=? or name like ?", q, q+'%'])
    end
  end

  def fees
    # this is hardcoded for the moment. later, when one has more than one client_type and one refactors, 
    # one will have to have this info read from the database
    Fee.all.select{|f| f.payable_on.to_s.split("_")[0].downcase == "client"}
  end

  def total_fees_due
    total_fees_due = fee_schedule.values.collect{|h| h.values}.flatten.inject(0){|a,b| a + b}
  end

  def total_fees_paid
    payments(:type => :fees, :loan_id => nil).sum(:amount) || 0
  end

  def total_fees_payable_on(date = Date.today)
    # returns one consolidated number
    total_fees_due = fee_schedule.select{|k,v| k <= date}.to_hash.values.collect{|h| h.values}.flatten.inject(0){|a,b| a + b}
    total_fees_due - total_fees_paid
  end

  def fees_payable_on(date = Date.today)
    # returns a hash of fee type and amounts
    schedule = fee_schedule.select{|k,v| k <= Date.today}.collect{|k,v| v.to_a}
    scheduled_fees = schedule.size > 0 ? schedule.map{|s| s.flatten}.to_hash : {}
    scheduled_fees - (fees_paid.values.inject({}){|a,b| a.merge(b)})
  end

  def fees_paid
    @fees_payments = {}
    payments(:type => :fees, :order => [:received_on], :loan => nil).each do |p|
      @fees_payments += {p.received_on => {p.comment => p.amount}}
    end
    @fees_payments
  end

  def fees_paid?
    total_fees_paid >= total_fees_due
  end

  def fee_schedule
    @fee_schedule = {}
    klass_identifier = self.class.to_s.snake_case
    fees.each do |f|
      type, *payable_on = f.payable_on.to_s.split("_")      
      if type == klass_identifier
        date = eval(payable_on.join("_"))
        @fee_schedule += {date => {f.name => f.fees_for(self)}} unless date.nil?
      end
    end
    @fee_schedule
  end

  def fee_payments
    @fees_payments = {}
  end

  def pay_fees(amount, date, received_by, created_by)
    @errors = []
    fp = fees_payable_on(date)
    pay_order = fee_schedule.keys.sort.map{|d| fee_schedule[d].keys}.flatten
    pay_order.each do |k|
      if fees_payable_on(date).has_key?(k)
        p = Payment.new(:amount => [fp[k],amount].min, :type => :fees, :received_on => date, :comment => k, 
                        :received_by => received_by, :created_by => created_by, :client => self)
        if p.save
          amount -= p.amount
          fp[k] -= p.amount
        else
          @errors << p.errors
        end
      end
    end
    @errors.blank? ? true : @errors
  end

  private
  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.send(k).type==Integer
        self.send("#{k}=", nil)
      end
    }
    self.type_of_account = 0 if self.type_of_account == nil
  end
end
