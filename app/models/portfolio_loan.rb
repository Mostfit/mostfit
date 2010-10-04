class PortfolioLoan
  include DataMapper::Resource

  property :id,             Serial
  property :loan_id,        Integer, :index => true, :nullable => false
  property :portfolio_id,   Integer, :index => true, :nullable => false
  property :original_value, Integer, :index => true, :nullable => false
  property :starting_value, Integer, :index => true, :nullable => false
  property :current_value,  Integer, :index => true, :nullable => false

  property :added_on,       Date, :index => true, :default => Date.today, :nullable => false
  property :active,         Boolean, :index => true, :default => true, :nullable => false

  belongs_to :portfolio
  belongs_to :loan

end
