class Application < Merb::Controller
  before :ensure_authenticated
  
  # move the following two functions into lib/logger.rb somehow
  def get_object_state
    debugger
    model = self.class.to_s.singular
    object = eval"#{model}.get(params[:id])"
    @ributes = object.attributes
  end
  
  def _log
    debugger
    f = File.open("log/#{self.class}.log","a")
    object = eval("@#{self.class.to_s.downcase.singular}")
    if object
      attributes = object.attributes
      diff = @ributes.diff(attributes)
      diff_string = diff.map{|k| "#{k} from #{@ributes[k]} to #{attributes[k]}" if k != :updated_at}.join("\t")
      log = "#{Time.now}\t#{session.user.login}\t#{diff_string}\n"
      f.write(log)
      f.close
      Merb.logger.info(log)
    end
  end


  def ensure_has_data_entry_privileges
    raise NotPrivileged unless session.user.data_entry_operator? || session.user.mis_manager? || session.user.admin?
  end

  def ensure_has_mis_manager_privileges
    raise NotPrivileged unless session.user.mis_manager? || session.user.admin?
  end

  def ensure_has_admin_privileges
    raise NotPrivileged unless session.user.admin?
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
end
