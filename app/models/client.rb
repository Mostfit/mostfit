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
  property :created_at,     DateTime
  property :deleted_at,     ParanoidDateTime
  property :account_number, String, :length => 20, :nullable => true
  property :type_of_account, Enum[0,:savings, :current, :no_frill, :fixed_deposit, :loan, :other]
  property :bank_name,      String, :length => 20, :nullable => true
  property :branch,         String, :length => 20, :nullable => true
  property :join_holder,    String, :length => 20, :nullable => true
  validates_length :account_number, :max => 20


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

  def self.active(query = {},operator = "=", num_loans = 1)
    client_ids = repository.adapter.query(%Q{
      SELECT (id) 
      FROM (
         SELECT COUNT(loan_id),lh.status, lh.loan_id, client_id as id
         FROM loan_history lh
         WHERE current = true AND lh.status <= 3
         GROUP BY client_id HAVING COUNT(loan_id) #{operator} #{num_loans}) as dt1;})
    query[:id.in] = client_ids unless client_ids.empty?
    Client.all(query)
  end

  def self.dormant(query = {}) # no loans outstanding
    client_ids = repository.adapter.query(%Q{
        SELECT id FROM clients WHERE id NOT IN
          (SELECT client_id FROM 
             (SELECT COUNT(loan_id), client_id 
              FROM loan_history 
              WHERE current = true AND status <= 3 
              GROUP BY client_id) AS dt)})
    query[:id.in] = client_ids unless client_ids.empty?
    Client.all(query)
  end

  def self.find_by_loan_cycle(loan_cycle, query = {})
    # a person is deemed to be in a loan_cycle if the number of repaid / written off loans he has is 
    # 1) equal to loan_cycle - 1 if he has a loan outstanding or
    # but ONLY IF loan_cycle > 1
    #
    # TODO
    # We can optimise this per model (i.e. branch) by returning one hash like {1 => 2436, 2 => 4367} etc
    if loan_cycle == 1
      client_ids = repository.adapter.query(" select client_id from (select count(client_id) as x, client_id, status from loan_history where current = true group by client_id having x = 1) as dt where dt.status <= 3")
    else
    # first find the Clients with repaid/written_off loans numbering loan_cycle - 1 and with loan outstanding
      client_ids = repository.adapter.query(%Q{
      SELECT (id) 
      FROM (
         SELECT COUNT(loan_id),client_id as id
         FROM loan_history lh
         WHERE current = true AND lh.status <= 3 and client_id in (
             SELECT id FROM 
               (SELECT COUNT(loan_id), client_id as id 
                FROM loan_history lh 
                WHERE current = true AND lh.status > 3 
                GROUP BY client_id 
                HAVING COUNT(loan_id) = #{loan_cycle - 1})  # this doesn't work for loan cycle one.
                AS dt) 
             GROUP BY client_id HAVING COUNT(loan_id) > 0) as dt1;})
    end
    query[:id.in] = client_ids unless client_ids.empty?
    Client.all(query)
  end


  private
  def convert_blank_to_nil
    self.type_of_account = 0 if self.type_of_account == nil
    self.center_id=nil       if self.center_id.blank?
    self.client_group_id=nil if self.client_group_id.blank? 
  end
end
