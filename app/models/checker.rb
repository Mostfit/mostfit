class Checker
  # Checkers validate data by comparing a known value with the result of an expression.
  # this class is actually only a Loan checked as an attempt to make a generic checker failed due to some problem saving Marshalled dates in the database
  # therefore, model_name is always Loan. We will attempt a generic checking mechanism when deadlines do not loom so heavy.

  include DataMapper::Resource
  
  before :save, :get_loan

  attr_accessor :value

  property :id, Serial
  property :model_name, String, :nullable => false
  property :unique_field, String
  property :reference,   String,:nullable => false, :unique => :model_name
  property :check_field, String, :nullable => false
  property :as_on, Date

  property :expected_value, Float
  property :actual_value,   Float
  property :checked,        Boolean, :default => false
  property :checked_at,     DateTime
  property :ok,             Boolean, :default => false

  belongs_to :upload
  belongs_to :loan

  def self.check_unchecked
    self.all(:checked => false).map{|c| c.check}
  end

  def get_loan
    self.loan ||= Loan.first(:reference => self.reference)
  end

  def check
    self.checked = true
    self.checked_at = DateTime.now
    self.actual_value = get_value
    if self.correct?
      self.ok = true
    end
    self.save
  end

  def correct?
    get_value unless @value
    expected_value.send({Float => :to_f, Integer => :to_i, String => :to_s}[@value.class]).round(4) == @value.round(4)
  end

  def get_value
    @value = Kernel.const_get(model_name).first(unique_field.to_sym => reference).send(check_field, as_on)
  end
  
  def set_arguments(x)
    self.arguments =  Marshal.dump([x].flatten)
  end

  def get_arguments
    Marshal.load(self.arguments)
  end

end
