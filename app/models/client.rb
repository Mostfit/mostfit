class Client
  include Paperclip::Resource
  include DateParser  # mixin for the hook "before :valid?, :parse_dates"
  include DataMapper::Resource

  before :valid?, :parse_dates
  
  property :id,             Serial
  property :reference,      String, :length => 100, :nullable => false
  property :name,           String, :length => 100, :nullable => false
  property :spouse_name,    String, :length => 100
  property :date_of_birth,  Date
  property :address,        Text
  property :active,         Boolean, :default => true, :nullable => false
  property :date_joined,    Date
  property :deleted_at,     ParanoidDateTime

  has_attached_file :picture,
      :styles => {:medium => "300x300>", :thumb => "60x60#"},
      :url => "/uploads/:class/:id/:attachment/:style/:basename.:extension",
      :path => "#{Merb.root}/public/uploads/:class/:id/:attachment/:style/:basename.:extension"

  has_attached_file :application_form,
      :styles => {:medium => "300x300>", :thumb => "60x60#"},
      :url => "/uploads/:class/:id/:attachment/:style/:basename.:extension",
      :path => "#{Merb.root}/public/uploads/:class/:id/:attachment/:style/:basename.:extension"

  has n, :loans
  belongs_to :center

  validates_length    :name, :min => 3
  validates_present   :center
  validates_is_unique :reference

  def self.active(query = {},operator = "=", num_loans = 1)
    debugger
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
end
