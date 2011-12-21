# dont call save or update or anything on this method directly!!
# this class is managed by the loan, and should be completely managed by it.

class Payment
  include DataMapper::Resource
  before :valid?, :parse_dates
  before :valid?, :check_client
  before :valid?, :add_center_and_branch
  # before :valid?, :add_loan_product_validations
  # after :valid?, :after_valid
  before :save, :put_fee
  attr_writer :total
  attr_accessor :override_create_observer  # just to be used in the form

  property :id,                  Serial
  property :guid,                String, :default => lambda{ |obj, p| UUID.generate }
  property :amount,              Float, :nullable => false, :index => true
  property :type,                Enum.send('[]',*PAYMENT_TYPES), :index => true
  property :comment,             String, :length => 50
  property :received_on,         Date,    :nullable => false, :index => true
  property :deleted_by_user_id,  Integer, :nullable => true
  # Default this one to today?
  property :created_at,          DateTime,:nullable => false, :index => true
  property :deleted_at,          ParanoidDateTime, :nullable => true, :index => true
  property :created_by_user_id,  Integer, :nullable => false, :index => true
  property :verified_by_user_id, Integer, :nullable => true, :index => true
  property :loan_id,             Integer, :nullable => true, :index => true
  property :client_id,           Integer, :nullable => true, :index => true
  property :c_center_id,           Integer, :nullable => true, :index => true
  property :c_branch_id,           Integer, :nullable => false, :index => true
  property :fee_id,              Integer, :nullable => true, :index => true
  property :desktop_id,          Integer
  property :origin,              String, :default => DEFAULT_ORIGIN

  belongs_to :organization, :parent_key => [:org_guid], :child_key => [:parent_org_guid], :required => false
  property   :parent_org_guid, String, :nullable => true
  
  belongs_to :domain, :parent_key => [:domain_guid], :child_key => [:parent_domain_guid], :required => false
  property   :parent_domain_guid, String, :nullable => true

  belongs_to :loan, :nullable => true
  belongs_to :client
  belongs_to :fee
  belongs_to :created_by,  :child_key => [:created_by_user_id],   :model => 'User'
  belongs_to :received_by, :child_key => [:received_by_staff_id], :model => 'StaffMember'
  belongs_to :deleted_by,  :child_key => [:deleted_by_user_id],   :model => 'User'
  belongs_to :verified_by,  :child_key => [:verified_by_user_id],        :model => 'User'

  validates_present     :created_by, :received_by, :if => Proc.new{|p| p.deleted_at == nil}
  validates_with_method :loan_or_client_present?,  :method => :loan_or_client_present?, :when => [:default, :reallocate]
  validates_with_method :only_take_payments_on_disbursed_loans?, :if => Proc.new{|p| (p.type == :principal or p.type == :interest)}
  validates_with_method :created_by,  :method => :created_by_active_user?, :if => Proc.new{|p| p.deleted_at == nil}
  validates_with_method :received_by, :method => :received_by_active_staff_member?, :when => [:default, :reallocate]
  validates_with_method :deleted_by,  :method => :properly_deleted?
  validates_with_method :deleted_at,  :method => :properly_deleted?
  validates_with_method :not_approved, :method => :not_approved, :on => [:destroy]

  # This is a little strange, we don't want to validate here while in the test environment? Disabling this validation in the test env is causing tests to fail.
  validates_with_method :received_on, :method => :not_received_in_the_future?, :unless => Proc.new{|t| Merb.env=="test"}
  validates_with_method :received_on, :method => :not_received_before_loan_is_disbursed?, :if => Proc.new{|p| (p.type == :principal or p.type == :interest)}
  validates_with_method :principal,   :method => :is_positive?
  validates_with_method :verified_by_user_id, :method => :verified_cannot_be_deleted, :on => [:destroy]
  validates_with_method :verified_by_user_id, :method => :verified_cannot_be_deleted, :if => Proc.new{|p| p.deleted_at != nil and p.deleted_by!=nil}
  # validates_with_method :is_last_payment?, :if => Proc.new{|p| p.deleted_at == nil and p.deleted_by == nil}
  
  def add_center_and_branch
    self.c_center_id = self.client.center.id
    self.c_branch_id = self.client.center.branch.id
  end

  def self.from_csv(row, headers, loans)
    if row[headers[:principal]]
      obj = new(:received_by => StaffMember.first(:name => row[headers[:received_by_staff]]), :loan => loans[row[headers[:loan_serial_number]]], 
                :amount => row[headers[:principal]], :type => :principal, :received_on => Date.parse(row[headers[:received_on]]), 
                :created_by => User.first)
      obj.save
    end
    
    if row[headers[:interest]]
      obj = new(:received_by => StaffMember.first(:name => row[headers[:received_by_staff]]), :loan => loans[row[headers[:loan_serial_number]]], 
                :amount => row[headers[:interest]], :type => :interest, :received_on => Date.parse(row[headers[:received_on]]), 
                :created_by => User.first)
    end
    [obj.save, obj]
  end

  def verified_cannot_be_deleted
    return true unless verified_by_user_id
    [false, "Verified payment. Cannot be deleted"]    
  end

  def total
    amount
  end

  def self.types
    PAYMENT_TYPES
  end
  
  # returns the amount collected by/under/for various kind of objects like Branch, Center, StaffMember, Area, Region, LoanProduct etc
  # TODO:  rewrite it using Datamapper
  # Something weird is going on here: at the end of this method the amount is cast .to_i. Is this intended behavior?
  def self.collected_for(obj, from_date=Date.min_date, to_date=Date.max_date, types=[1,2], payment_created_type = :created)
    from, where = "", ""
    if obj.class==Branch
      from  = "branches b, centers c, clients cl, loans l , payments p"
      where = %Q{
                  b.id=#{obj.id} and c.branch_id=b.id and cl.center_id=c.id and l.client_id=cl.id and p.loan_id=l.id and p.type in (#{types.join(',')})
               };
    elsif obj.class==Center
      from  = "centers c, clients cl, loans l , payments p"
      where = %Q{
                  c.id=#{obj.id} and cl.center_id=c.id and l.client_id=cl.id and p.loan_id=l.id and p.type in (#{types.join(',')})
               };
    elsif obj.class==ClientGroup
      from  = "client_groups cg, clients cl, loans l , payments p"
      where = %Q{
                 cg.id=#{obj.id} and cg.id=c.client_group_id and l.client_id=cl.id and p.loan_id=l.id and p.type in (#{types.join(',')})
              };
    elsif obj.class==Area
      from  = "areas a, branches b, centers c, clients cl, loans l , payments p"
      where = %Q{
                  a.id=#{obj.id} and a.id=b.area_id and c.branch_id=b.id and cl.center_id=c.id 
                  and l.client_id=cl.id and p.loan_id=l.id and p.type in (#{types.join(',')})
               };
    elsif obj.class==Region
      from  = "regions r, areas a, branches b, centers c, clients cl, loans l , payments p"
      where = %Q{
                  r.id=#{obj.id} and r.id=a.region_id and a.id=b.area_id and c.branch_id=b.id and cl.center_id=c.id 
                  and l.client_id=cl.id and p.loan_id=l.id and p.type in (#{types.join(',')})
               };
    elsif obj.class==StaffMember
      if payment_created_type == :created
        from  = "payments p"
        where = %Q{         
                  p.received_by_staff_id=#{obj.id} and p.type in (#{types.join(',')})
               };
      else
        from  = "centers c, clients cl, loans l , payments p"
        where = %Q{
                  c.manager_staff_id=#{obj.id} and cl.center_id=c.id and l.client_id=cl.id and p.loan_id=l.id and p.type in (#{types.join(',')})
               };
      end
    elsif obj.class==LoanProduct
      from  = "loans l, payments p"
      where = %Q{                  
                  l.id = p.loan_id and l.deleted_at is NULL and l.loan_product_id = #{obj.id} and p.type in (#{types.join(',')})
               };
    elsif obj.class==Loan
      from  = "loans l, payments p"
      where = %Q{                  
                  l.id = p.loan_id and l.deleted_at is NULL and l.id = #{obj.id} and p.type in (#{types.join(',')})
               };
    elsif obj.class==Client
      from  = "clients cl, payments p"
      where = %Q{                  
                   p.type in (#{types.join(',')}) and cl.id=p.client_id and cl.id=#{obj.id}
               };
    elsif obj.class==FundingLine
      from  = "loans l, payments p"
      where = %Q{                  
                  l.id = p.loan_id and l.deleted_at is NULL and l.funding_line_id = #{obj.id} and p.type in (#{types.join(',')})
               };
    end
    where += "AND p.deleted_at is NULL AND p.received_on>='#{from_date.strftime('%Y-%m-%d')}' AND p.received_on<='#{to_date.strftime('%Y-%m-%d')}'"
    repository.adapter.query(%Q{
                             SELECT SUM(p.amount) amount, p.type payment_type
                             FROM #{from}
                             WHERE #{where}
                             GROUP BY type
                           }).map{|x| {Payment.types[x.payment_type-1] => x.amount.to_i}}.inject({}){|s,x| s+=x}
  end

  def extended_info
    info_items = []
    loan_product = self.loan ? self.loan.loan_product : nil
    funding_line = self.loan ? self.loan.funding_line : nil
    branch = self.loan ? self.loan.client.center.branch : nil

    if branch
      info = {}
      info[:item_type] = branch.class.to_s
      info[:item_id] = branch.id
      info[:item_value] = branch.name
      info_items << info
    end
    
    if loan_product
      info = {}
      info[:item_type] = loan_product.class.to_s
      info[:item_id] = loan_product.id
      info[:item_value] = loan_product.name
      info_items << info
    end
    
    if funding_line
      info = {}
      info[:item_type] = funding_line.class.to_s
      info[:item_id] = funding_line.id
      info[:item_value] = funding_line.name
      info_items << info
    end
    info_items
  end

  private
  include DateParser  # mixin for the hook "before: valid?, :parse_dates"
  include Misfit::PaymentValidators
  def add_loan_product_validations
    return unless loan and loan.loan_product
    # THIS WORKS
#    clause = eval "Proc.new{|t| t.loan.loan_product.id == 1}"
    #Payment.add_validator_to_context({:context => :default}, 
    #                                 loan.loan_product.payment_validations, DataMapper::Validate::MethodValidator)
    Payment.add_validator_to_context({:context => :default, :if => eval("Proc.new{|t| t.loan.loan_product.id == #{loan.loan_product.id}}")}, loan.loan_product.payment_validations,DataMapper::Validate::MethodValidator)
  end

  def check_client
    self.client = loan.client if loan and not client
  end

  def is_same_product
    true
  end

  def after_valid
  end

  def loan_or_client_present?
    return [false, "Needs to belong either to a loan or to a client"] unless (loan or client)
    return true
  end

  def created_by_active_user?
    return true if created_by and created_by.active
    [false, "Payments can only be created if an active user is supplied"]
  end

  def received_by_active_staff_member?
    return true if self.send(:current_validation_context) == :reallocate
    return true if deleted_at
    return true if received_by and received_by.active
    [false, "Receiving staff member is currently not active"]
  end

  def properly_deleted?
    return true if (deleted_by and deleted_at) or (!deleted_by and !deleted_at)
    [false, "deleted_by and deleted_at properties have to be (un)set together"]
  end

  def allowed_edit?
    orig = self.class.get(self.id)
    if verified_by_user_id and verified_by_user_id>0 and orig.verified_by_user_id and orig.verified_by_user_id>0
      return [false, "Cannot delete or edit an approved payment"]
    else
      return true
    end
  end

  # This assumes a payment is related to a loan, if no loan is present it fails the validation without warning (nil is returned)
  def only_take_payments_on_disbursed_loans?
    return true if deleted_at
    if loan
      return true if [:outstanding, :disbursed, :repaid, :written_off].include?(loan.get_status(received_on))
      [false, "Payments cannot be made on loans that are written off, repaid or not (yet) disbursed. This loan is #{loan.get_status(received_on)}"]
    end
  end

  def not_received_in_the_future?
    return true if received_on <= Date.today + Mfi.first.number_of_future_days
    [false, "Payments cannot be received in the future"]
  end

  def not_received_in_past_upto?
    past_days = Mfi.first.number_of_past_days
    if Mfi.first.min_date_from == :in_operation_since
      eligible_date = Mfi.first.in_operation_since - past_days
    else
      eligible_date = Date.today- past_days
    end 
    return true if received_on >= eligible_date
    [false, "Payments cannot be received in past date"]
  end

  # Again if no loan is associated with this payment this validation fails silently
  def not_received_before_loan_is_disbursed?
    if loan
      return [false, "Payments cannot be received before the loan is disbursed"] if loan.disbursal_date.blank?
      return [false, "Payments cannot be received before the loan disbursal date"] if loan.disbursal_date > received_on
      return true
    end
  end

  def is_last_payment?
    return true if type == :fees
    return true unless loan.c_last_payment_received_on
    return [false, "Payments cannot be received on a date before the last actual payment"] if received_on <= loan.c_last_payment_received_on
    return true
  end

  def put_fee
    if type==:fees and comment and not fee
      self.fee = Fee.first(:name => comment)
    end
  end

  def is_positive?
    return true if amount.blank? ? true : amount >= 0
    [false, "Amount cannot be less than zero"]
  end

end
