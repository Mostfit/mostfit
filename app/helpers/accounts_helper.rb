module Merb
  module AccountsHelper
    def show_accounts(account)
      children = account.children
      if children.length == 0
        return "<li>#{account.name}#{"<span class=\"branchName\">" + account.branch.name + '</span>' if account.branch}</li>"
      else
        return "<ul><li>#{account.name}<ul>" + children.map{|child_account|
          show_accounts(child_account)
        }.join + "</ul></li></ul>"
      end
    end
    
  end
end # Merb
