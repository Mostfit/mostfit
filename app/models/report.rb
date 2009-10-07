class Report
  include DataMapper::Resource

  attr_accessor :raw
  property :id, Serial
  property :start_date, Date
  property :end_date, Date
  property :report, Yaml
  property :dirty, Boolean
  property :report_type, Discriminator
  property :created_at, DateTime
  property :generation_time, Integer

  def name
    "#{report_type}: #{start_date} - #{end_date}"
  end
end
