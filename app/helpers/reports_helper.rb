module Merb
  module ReportsHelper
    def get_printer_url
      request.env["REQUEST_URI"] + (request.env["REQUEST_URI"].index("?") ? "&" : "?") + "layout=printer"
    end    

    def show_accounts(account)
      return unless account
      if account.class == Account
        return "<li><span class=\"spacer1\">#{account.name}</span><span class=\"spacer2\">#{account.opening_balance}</span><span class=\"spacer3\">#{account.debit}</span><span class=\"spacer4\">#{account.credit}</span><span class=\"spacer5\">#{account.balance}</span></li>"
      else
        return "<ul><li><span class=\"spacer1\">#{account.first.name}</span><span class=\"spacer2\">#{account.first.opening_balance}</span><span class=\"spacer3\">#{account.first.debit}</span><span class=\"spacer4\">#{account.first.credit}</span><span class=\"spacer5\">#{account.first.balance}</span><ul>" + account.last.map{|child_account|
          show_accounts(child_account)
        }.join + "</ul></li></ul>"
      end
    end    
  end
end # Merb
