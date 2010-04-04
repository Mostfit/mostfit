module Merb
  module ReportsHelper
    def get_printer_url
      request.env["REQUEST_URI"] + (request.env["REQUEST_URI"].index("?") ? "&" : "?") + "layout=printer"
    end    
  end
end # Merb
