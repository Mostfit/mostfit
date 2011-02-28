class Guarantor
  include DataMapper::Resource

  property :id,   Serial
  property :name, String, :length => 100, :index => true
  property :father_name, String, :length => 100, :index => true
  property :date_of_birth, Date
  property :gender,     Enum.send('[]', *['', 'female', 'male']), :nullable => true, :lazy => true
  property :address, String, :length => 100 
  property :relationship_to_client, Enum.send('[]', *['', 'spouse', 'brother', 'brother_in_law', 'father', 'father_in_law', 'adult_son', 'other']), :default => '', :nullable => true, :lazy => true
  property :created_at,      DateTime, :default => Time.now
 
  belongs_to :client
  belongs_to :guarantor_occupation, :nullable => true, :child_key => [:guarantor_occupation_id], :model => 'Occupation'  
  validates_present :name
  validates_present :father_name
  validates_length :name,   :minimum => 3
  validates_length :father_name,   :minimum => 3
end

# We migrated data for Intellecash using the followng
# to copy over data for existing guarantors from the clients table into the new guarantors table:
# insert into guarantors(name, father_name, date_of_birth, address, relationship_to_client, guarantor_occupation_id, client_id, created_at)  select guarantor_name, guarantor_fathers_name, guarantor_date_of_birth, guarantor_address, guarantor_relationship, guarantor_occupation_id, id, created_at from clients;
