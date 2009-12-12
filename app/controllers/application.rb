class Application < Merb::Controller
  before :ensure_authenticated
  before :ensure_can_do

  def ensure_can_do
    @route = Merb::Router.match(request)
    raise NotPrivileged unless session.user.can_access?(@route[1], params)
  end

  def render_to_pdf(options = nil)
    data = render_to_string(options)
    pdf = PDF::HTMLDoc.new
    pdf.set_option :bodycolor, :white
    pdf.set_option :toc, false
    pdf.set_option :portrait, true
    pdf.set_option :links, false
    pdf.set_option :webpage, true
    pdf.set_option :left, '2cm'
    pdf.set_option :right, '2cm'
    pdf << data
    pdf.generate
  end
end



