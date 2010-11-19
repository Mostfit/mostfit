module Merb
  module ReportsHelper
    def get_printer_url
      request.env["REQUEST_URI"] + (request.env["REQUEST_URI"].index("?") ? "&" : "?") + "layout=printer"
    end    

    def show_accounts(account)
      return unless account
      if account.class == Account
        return "<li><span class=\"spacer1\">#{account.name}</span><span class=\"spacer2a\">#{account.opening_balance_debit.to_currency}</span><span class=\"spacer2b\">#{account.opening_balance_credit.to_currency}</span><span class=\"spacer3a\">#{account.debit.to_currency}</span><span class=\"spacer3b\">#{account.credit.to_currency}</span><span class=\"spacer4a\">#{account.balance_debit.to_currency}</span><span class=\"spacer4b\">#{account.balance_credit.to_currency}</span></li>"
      else
        return "<ul><li><span class=\"spacer1\">#{account.first.name}</span><span class=\"spacer2a\">#{account.first.opening_balance_debit.to_currency}</span><span class=\"spacer2b\">#{account.first.opening_balance_credit.to_currency}</span><span class=\"spacer3a\">#{account.first.debit.to_currency}</span><span class=\"spacer3b\">#{account.first.credit.to_currency}</span><span class=\"spacer4a\">#{account.first.balance_debit.to_currency}</span><span class=\"spacer4b\">#{account.first.balance_credit.to_currency}</span><ul>" + account.last.map{|child_account|
          show_accounts(child_account)
        }.join + "</ul></li></ul>"
      end
    end    
  end
end # Merb
