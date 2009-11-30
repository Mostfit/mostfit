class Report
  include DataMapper::Resource

  attr_accessor :raw
  property :id, Serial
  property :start_date, Date
  property :end_date, Date
  property :report, Yaml, :length => 20000
  property :dirty, Boolean
  property :report_type, Discriminator
  property :created_at, DateTime
  property :generation_time, Integer

  def name
    "#{report_type}: #{start_date} - #{end_date}"
  end

  def get_pdf
    pdf = PDF::HTMLDoc.new
    pdf.set_option :bodycolor, :white
    pdf.set_option :toc, false
    pdf.set_option :portrait, true
    pdf.set_option :links, true
    pdf.set_option :webpage, true
    pdf.set_option :left, '2cm'
    pdf.set_option :right, '2cm'
    pdf.set_option :header, "Header here!"
    f = File.read("app/views/reports/_#{name.snake_case.gsub(" ","_")}.pdf.haml")
    report = Haml::Engine.new(f).render(Object.new, :report => self)
    pdf << report
    pdf.footer ".t."
    pdf
  end
end
