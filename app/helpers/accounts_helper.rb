module Merb
  module AccountsHelper
    def show_accounts(accounts)
      if accounts.is_a?(Array)
        return if accounts.length == 0
        first_account, rest_accounts = accounts[0], accounts[1..-1]||[]
        ((first_account.is_a?(Account) ? output_li(first_account, false) : show_accounts(first_account)) + rest_accounts.map{|account|
           if account.is_a?(Account)
             output_li(account)
           elsif account.is_a?(Array) and account.length == 1 and account.first.is_a?(Account)
             output_li(account.first)
           elsif account.is_a?(Array) and account.length > 0
             "<ul>#{show_accounts(account)}</ul>"
           end
         }.join + "</li>").gsub("<ul></li></ul>", "")
      else
        output_li(accounts)
      end
    end

    private
    def output_li(account, emit_closing=true)
      account.branch_edge ? "<li>#{link_to(account.name, resource(account))}#{"<span class=\"branchName\">" + account.branch.name + '</span>' if account.branch}#{emit_closing ? '</li>' : ''}" : ""
    end
  end
end # Merb
