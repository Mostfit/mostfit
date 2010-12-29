module Merb
  module ReportsHelper
    def get_printer_url
      request.env["REQUEST_URI"] + (request.env["REQUEST_URI"].index("?") ? "&" : "?") + "layout=printer"
    end    

    def show_accounts(account, depth=1)
      return unless account
      if account.class == Account
        return output_li(account, depth)
      else
        (account.first.is_a?(Account) ? output_li(account.first, depth) : show_accounts(account.first, depth)) + "<ul>" + (account[1..-1]||[]).first.map{|child_account|
          show_accounts(child_account, depth + 1)
        }.join("") + "</li></ul>"
       end
     end

    private
    def output_li(account, depth)
      return %{
               <li class='depth_#{depth}'>
                 <span class='spacer1'>#{account.name}</span>
                 <span class='spacer2a'>#{account.opening_balance_debit.to_currency}</span>
                 <span class='spacer2b'>#{account.opening_balance_credit.to_currency}</span>
                 <span class='spacer3a'>#{account.debit.to_currency}</span>
                 <span class='spacer3b'>#{account.credit.to_currency}</span>
                 <span class='spacer4a'>#{account.balance_debit.to_currency}</span>
                 <span class='spacer4b'>#{account.balance_credit.to_currency}</span>
             }
    end
  end
end # Merb
