module Merb
  module AccountsHelper
    def show_accounts(account)
      children = account.children
      if children.length == 0
        return "<li>#{link_to(account.name, resource(account))}#{"<span class=\"branchName\">" + account.branch.name + '</span>' if account.branch}</li>"
      else
        return "<ul><li>#{link_to(account.name, resource(account))}<ul>" + children.map{|child_account|
          show_accounts(child_account)
        }.join + "</ul></li></ul>"
      end
    end
    
  end
end # Merb
