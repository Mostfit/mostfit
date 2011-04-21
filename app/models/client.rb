class Client
  include Paperclip::Resource
  include DateParser  # mixin for the hook "before :valid?, :parse_dates"
  include DataMapper::Resource
  include FeesContainer

  FLAGS = [:insincere]

  before :valid?, :parse_dates
  before :valid?, :convert_blank_to_nil
  before :valid?, :add_created_by_staff_member
  after  :save,   :check_client_deceased
  after  :save,   :levy_fees
  
  property :id,              Serial
  property :reference,       String, :length => 100, :nullable => false, :index => true
  property :name,            String, :length => 100, :nullable => false, :index => true
  property :spouse_name,     String, :length => 100, :lazy => true
  property :date_of_birth,   Date,   :index => true, :lazy => true
  property :address,         Text, :lazy => true
  property :active,          Boolean, :default => true, :nullable => false, :index => true
  property :inactive_reason, Enum.send('[]', *INACTIVE_REASONS), :nullable => true, :index => true, :default => ''
  property :date_joined,     Date,    :index => true
  property :grt_pass_date,   Date,    :index => true, :nullable => true
  property :client_group_id, Integer, :index => true, :nullable => true
  property :center_id,       Integer, :index => true, :nullable => true
  property :created_at,      DateTime, :default => Time.now
  property :deleted_at,      ParanoidDateTime
  property :updated_at,      DateTime
  property :deceased_on,     Date, :lazy => true
#  property :client_type,     Enum["standard", "takeover"] #, :default => "standard"
  property :created_by_user_id,  Integer, :nullable => false, :index => true
  property :created_by_staff_member_id,  Integer, :nullable => false, :index => true
  property :verified_by_user_id, Integer, :nullable => true, :index => true
  property :tags, Flag.send("[]", *FLAGS)

  property :account_number, String, :length => 20, :nullable => true, :lazy => true
  property :type_of_account, Enum.send('[]', *['', 'savings', 'current', 'no_frill', 'fixed_deposit', 'loan', 'other']), :lazy => true
  property :bank_name,      String, :length => 20, :nullable => true, :lazy => true
  property :bank_branch,         String, :length => 20, :nullable => true, :lazy => true
  property :join_holder,    String, :length => 20, :nullable => true, :lazy => true
#  property :client_type,    Enum[:default], :default => :default
  property :number_of_family_members, Integer, :length => 10, :nullable => true, :lazy => true
  property :school_distance, Integer, :length => 10, :nullable => true, :lazy => true
  property :phc_distance, Integer, :length => 10, :nullable => true, :lazy => true
  property :member_literate, Enum.send('[]', *['', 'no', 'yes']), :default => '', :nullable => true, :lazy => true
  property :husband_litrate, Enum.send('[]', *['', 'no', 'yes']), :default => '', :nullable => true, :lazy => true
  property :other_productive_asset, String, :length => 30, :nullable => true, :lazy => true
  property :income_regular, Enum.send('[]', *['', 'no', 'yes']), :default => '', :nullable => true, :lazy => true
  property :client_migration, Enum.send('[]', *['', 'no', 'yes']), :default => '', :nullable => true, :lazy => true
  property :pr_loan_amount, Integer, :length => 10, :nullable => true, :lazy => true
  property :other_income, Integer, :length => 10, :nullable => true, :lazy => true
  property :total_income, Integer, :length => 10, :nullable => true, :lazy => true
  property :poverty_status, String, :length => 10, :nullable => true, :lazy => true
  property :children_girls_under_5_years, Integer, :length => 10, :default => 0, :lazy => true
  property :children_girls_5_to_15_years, Integer, :length => 10, :default => 0, :lazy => true
  property :children_girls_over_15_years, Integer, :length => 10, :default => 0, :lazy => true
  property :children_sons_under_5_years, Integer, :length => 10, :default => 0, :lazy => true
  property :children_sons_5_to_15_years, Integer, :length => 10, :default => 0, :lazy => true
  property :children_sons_over_15_years, Integer, :length => 10, :default => 0, :lazy => true
  property :not_in_school_working_girls, Integer, :length => 10, :default => 0, :lazy => true
  property :not_in_school_bonded_girls, Integer, :length => 10, :default => 0, :lazy => true
  property :not_in_school_working_sons, Integer, :length => 10, :default => 0, :lazy => true
  property :not_in_school_bonded_sons, Integer, :length => 10, :default => 0, :lazy => true
  property :irrigated_land_own_fertile, Integer, :lazy => true
  property :irrigated_land_leased_fertile, Integer, :lazy => true
  property :irrigated_land_shared_fertile, Integer, :lazy => true
  property :irrigated_land_own_semifertile, Integer, :lazy => true
  property :irrigated_land_leased_semifertile, Integer, :lazy => true
  property :irrigated_land_shared_semifertile, Integer, :lazy => true
  property :irrigated_land_own_wasteland, Integer, :lazy => true
  property :irrigated_land_leased_wasteland, Integer, :lazy => true
  property :irrigated_land_shared_wasteland, Integer, :lazy => true
  property :not_irrigated_land_own_fertile, Integer, :lazy => true
  property :not_irrigated_land_leased_fertile, Integer, :lazy => true
  property :not_irrigated_land_shared_fertile, Integer, :lazy => true
  property :not_irrigated_land_own_semifertile, Integer, :lazy => true
  property :not_irrigated_land_leased_semifertile, Integer, :lazy => true
  property :not_irrigated_land_shared_semifertile, Integer, :lazy => true
  property :not_irrigated_land_own_wasteland, Integer, :lazy => true
  property :not_irrigated_land_leased_wasteland, Integer, :lazy => true
  property :not_irrigated_land_shared_wasteland, Integer, :lazy => true
  property :caste, Enum.send('[]', *['', 'sc', 'st', 'obc', 'general']), :default => '', :nullable => true, :lazy => true
  property :religion, Enum.send('[]', *['', 'hindu', 'muslim', 'sikh', 'jain', 'buddhist', 'christian']), :default => '', :nullable => true, :lazy => true
  validates_length :number_of_family_members, :max => 20
  validates_length :school_distance, :max => 200
  validates_length :phc_distance, :max => 500

  has n, :loans
  has n, :payments
  has n, :insurance_policies
  has n, :attendances
  has n, :claims
  has n, :guarantors
  has n, :applicable_fees,    :child_key => [:applicable_id], :applicable_type => "Client"
  validates_length :account_number, :max => 20

  belongs_to :center
  belongs_to :client_group
  belongs_to :occupation, :nullable => true
  belongs_to :client_type
  belongs_to :created_by,        :child_key => [:created_by_user_id],         :model => 'User'
  belongs_to :created_by_staff,  :child_key => [:created_by_staff_member_id], :model => 'StaffMember'
  belongs_to :verified_by,       :child_key => [:verified_by_user_id],        :model => 'User'

  has_attached_file :picture,
    :styles => {:medium => "300x300>", :thumb => "60x60#"},
    :url => "/uploads/:class/:id/:attachment/:style/:basename.:extension",
    :path => "#{Merb.root}/public/uploads/:class/:id/:attachment/:style/:basename.:extension",
    :default_url => "/images/no_photo.jpg"

  has_attached_file :application_form,
    :styles => {:medium => "300x300>", :thumb => "60x60#"},
    :url => "/uploads/:class/:id/:attachment/:style/:basename.:extension",
    :path => "#{Merb.root}/public/uploads/:class/:id/:attachment/:style/:basename.:extension"

  has_attached_file :fingerprint,
    :url => "/uploads/:class/:id/:basename.:extension",
    :path => "#{Merb.root}/public/uploads/:class/:id/:basename.:extension"

  validates_length    :name, :min => 3
  validates_present   :center
  validates_present   :date_joined
  validates_is_unique :reference
  validates_with_method  :verified_by_user_id,          :method => :verified_cannot_be_deleted, :if => Proc.new{|x| x.deleted_at != nil}
  validates_attachment_thumbnails :picture
  validates_with_method :date_joined, :method => :dates_make_sense
  validates_with_method :inactive_reason, :method => :cannot_have_inactive_reason_if_active

  def self.from_csv(row, headers)
    if center_attr = row[headers[:center]].strip
      if center   = Center.first(:name => center_attr)
      elsif center   = Center.first(:code => center_attr)
      elsif /\d+/.match(center_attr)
        center   = Center.get(center_attr)
      end
    end
    return unless center
    branch         = center.branch
    #creating group either on group ccode(if a group sheet is present groups should be already in place) or based on group name
    if headers[:group_code] and row[headers[:group_code]]
      client_group  =  ClientGroup.first(:code => row[headers[:group_code]].strip)
    elsif headers[:group] and row[headers[:group]]
      name          = row[headers[:group]].strip
      client_group  = ClientGroup.first(:name => name)||ClientGroup.create(:name => name, :center => center, :code => name.split(' ').join)
    else
      client_group  = nil
    end
    client_type     = ClientType.first||ClientType.create(:type => "Standard")
    grt_date        = row[headers[:grt_date]] ? Date.parse(row[headers[:grt_date]]) : nil
    obj             = new(:reference => row[headers[:reference]], :name => row[headers[:name]], :spouse_name => row[headers[:spouse_name]],
                          :date_of_birth => Date.parse(row[headers[:date_of_birth]]), :address => row[headers[:address]], :date_joined => row[headers[:date_joined]],
                          :center => center, :grt_pass_date => grt_date, :created_by => User.first,
                          :client_group => client_group, :client_type => client_type)
    [obj.save, obj]
  end

  def self.search(q, per_page=10)
    if /^\d+$/.match(q)
      all(:conditions => {:id => q}, :limit => per_page)
    else
      all(:conditions => ["reference=? or name like ?", q, q+'%'], :limit => per_page)
    end
  end

  def pay_fees(amount, date, received_by, created_by)
    @errors = []
    fp = fees_payable_on(date)
    pay_order = fee_schedule.keys.sort.map{|d| fee_schedule[d].keys}.flatten
    pay_order.each do |k|
      if fees_payable_on(date).has_key?(k)
        pay = Payment.new(:amount => [fp[k], amount].min, :type => :fees, :received_on => date, :comment => k.name, :fee => k,
                          :received_by => received_by, :created_by => created_by, :client => self)        
        if pay.save_self
          amount -= pay.amount
          fp[k] -= pay.amount
        else
          @errors << pay.errors
        end
      end
    end
    @errors.blank? ? true : @errors
  end

  def self.flags
    FLAGS
  end

  def make_center_leader
    return "Already is center leader for #{center.name}" if CenterLeader.first(:client => self, :center => self.center)
    CenterLeader.all(:center => center, :current => true).each{|cl|
      cl.current = false
      cl.date_deassigned = Date.today
      cl.save
    }
    CenterLeader.create(:center => center, :client => self, :current => true, :date_assigned => Date.today)
  end

  def check_client_deceased
    if not self.active and not self.inactive_reason.blank? and [:death_of_client, :death_of_spouse].include?(self.inactive_reason.to_sym)
      loans.each do |loan|
        if (loan.status==:outstanding or loan.status==:disbursed or loan.status==:claim_settlement) and self.claims.length>0 and claim=self.claims.last
          if claim.stop_further_installments
            last_payment_date = loan.payments.aggregate(:received_on.max)
            #set date of stopping payments/claim settlement one ahead of date of last payment
            if last_payment_date and (last_payment_date > claim.date_of_death) 
              loan.under_claim_settlement = last_payment_date + 1
            elsif claim.date_of_death
              loan.under_claim_settlement = claim.date_of_death
            else
              loan.under_claim_settlement = Date.today
            end
            loan.save
          end
        end
      end
    end
  end

  private
  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.send(k).type==Integer
        self.send("#{k}=", nil)
      end
    }
    self.type_of_account = 0 if self.type_of_account == nil
    self.occupation = nil if self.occupation.blank?
    self.type_of_account = '' if self.type_of_account.nil? or self.type_of_account=="0"
  end

  def add_created_by_staff_member
    if self.center and self.new?
      self.created_by_staff_member_id = self.center.manager_staff_id
    end
  end

  def dates_make_sense
    return true if not grt_pass_date or not date_joined 
    return [false, "Client cannot join this center before the center was created"] if center and center.creation_date and center.creation_date > date_joined
    return [false, "GRT Pass Date cannot be before Date Joined"]  if grt_pass_date < date_joined
    return [false, "Client cannot die before he became a client"] if deceased_on and (deceased_on < date_joined or deceased_on < grt_pass_date)
    true
  end

  def verified_cannot_be_deleted
    return true unless verified_by_user_id
    throw :halt
    [false, "Verified client. Cannot be deleted"]
  end

  def self.death_cases(obj, from_date, to_date)
     d2 = to_date.strftime('%Y-%m-%d')
    if obj.class == Branch 
      from  = "branches b, centers c, clients cl, claims cm"
      where = %Q{
                cl.active = false AND cl.inactive_reason IN (2,3) AND cl.id = cm.client_id AND cm.claim_submission_date >= #{from_date.strftime('%Y-%m-%d')} AND cm.claim_submission_date <= 'd2' AND cl.center_id = c.id AND c.branch_id = b.id  AND b.id = #{obj.id}   
                };
      
    elsif obj.class == Center
      from  = "centers c, clients cl, claims cm"     
      where = %Q{
               cl.active = false AND cl.inactive_reason IN (2,3) AND cl.id = cm.client_id AND cm.claim_submission_date >= #{from_date.strftime('%Y-%m-%d')} AND cm.claim_submission_date <= 'd2' AND cl.center_id = c.id AND c.id = #{obj.id}   
                };
      
    elsif obj.class == StaffMember
      # created_by_staff_member_id
      from =  "clients cl, claims cm, staff_members sm"      
      where = %Q{
                cl.active = false AND cl.inactive_reason IN (2,3)  AND cl.id = cm.client_id AND cm.claim_submission_date >= #{from_date.strftime('%Y-%m-%d')} AND cm.claim_submission_date <= 'd2' AND cl.created_by_staff_member_id = sm.id AND sm.id = #{obj.id}    
                };
      
    end
    repository.adapter.query(%Q{
                             SELECT COUNT(cl.id)
                             FROM #{from}
                             WHERE #{where}
                           })
  end
  
   def self.pending_death_cases(obj,from_date, to_date) 
     if obj.class == Branch
       repository.adapter.query(%Q{
                                SELECT COUNT(cl.id)
                                FROM branches b, centers c, clients cl, claims cm
                                WHERE cl.active = false AND cl.inactive_reason IN (2,3)
                                AND cl.center_id = c.id AND c.branch_id = b.id 
                                AND b.id = #{obj.id} AND cl.id NOT IN (SELECT client_id FROM claims)     
                               })
       
     elsif obj.class == Center      
       repository.adapter.query(%Q{
                                SELECT COUNT(cl.id)
                                FROM centers c, clients cl, claims cm 
                                WHERE cl.active = false AND cl.inactive_reason IN (2,3)
                                AND cl.center_id = c.id AND c.id = #{obj.id} AND cl.id
                                NOT IN (SELECT client_id FROM claims )   
                              })

     elsif obj.class == StaffMember
       repository.adapter.query(%Q{
                                SELECT COUNT(cl.id)
                                FROM clients cl, claims cm, staff_members sm 
                                WHERE cl.active = false AND cl.inactive_reason IN (2,3)
                                AND cl.created_by_staff_member_id = sm.id AND sm.id = #{obj.id} AND cl.id
                                NOT IN (SELECT client_id FROM claims )
                                })
     end
   end
   
   def cannot_have_inactive_reason_if_active
     return [false, "cannot have a inactive reason if active"] if self.active and not inactive_reason.blank?
     return true
   end

 end
