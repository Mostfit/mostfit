class Organization
  include DataMapper::Resource
  
  property :id,       Serial
  property :org_guid, String
  property :name,     String

  has 1, :accounting_period
  has n, :domains
  has n, :payments, :parent_key => [:org_guid], :child_key => [:parent_org_guid]
  
  def self.get_organization(date)
    accounting_period = AccountingPeriod.get_accounting_period(date)
    org = accounting_period ? accounting_period.organization : Organization.first #Default it to the first organization 
    org
  end
end
