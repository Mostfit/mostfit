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


# small monkey patch, real patch is submitted to extlib/merb/dm, hoping for inclusion soon
class Date
  def inspect
    "<Date: #{self.to_s}>"
  end
end


#Hash diffs are easy
class Hash
  def diff(other)
    keys = self.keys
    keys.each.select{|k| self[k] != other[k]}
  end

  def / (other)
    rhash = {}
    keys.each do |k|
      if self.has_key?(k) and other.has_key?(k)
        rhash[k] = self[k]/other[k]
      else
        rhash[k] = nil
      end
    end
    rhash
  end

  def - (other)
    rhash = {}
    keys.each do |k|
      if has_key?(k) and other.has_key?(k)
        rhash[k] = self[k] - other[k]
      else
        rhash[k] = nil
      end
    end
    rhash
  end
end
