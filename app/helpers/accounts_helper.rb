module Merb
  module AccountsHelper
    def show_accounts(accounts, depth = 0, tag = 'ul', selected = nil)
      subtag = tag == 'ul' ? 'li' : 'option'
      
      if accounts.is_a?(Array)
        return if accounts.length == 0
        first_account, rest_accounts = accounts[0], accounts[1..-1]||[]
        rv = ((first_account.is_a?(Account) ? output_li(first_account, depth, tag, false) : show_accounts(first_account, depth, tag)) + rest_accounts.map{|account|
                if account.is_a?(Account)
                  output_li(account, depth, tag, selected)
                elsif account.is_a?(Array) and account.length == 1 and account.first.is_a?(Account)
                  output_li(account.first, depth, tag, selected)
                elsif account.is_a?(Array) and account.length > 0
                  if tag == 'ul'
                    "<ul>#{show_accounts(account, depth + 1, tag)}</ul>"
                  else
                    show_accounts(account, depth + 1, tag, selected)
                  end
                end
              }.join)
        rv = (rv + "</li>").gsub("<ul></li></ul>", "") if tag == 'ul'
      else
        rv = output_li(accounts, depth, tag, selected)
      end
      return rv
    end

    private
    
    def output_li(account, depth, tag, emit_closing=true, selected = nil)
      if tag == 'ul'
        return ( account.branch_edge ? "<li>#{link_to(account.name, resource(account))}#{"<span class=\"branchName\">" + account.branch.name + '</span>' if account.branch}#{emit_closing ? '</li>' : ''}" : "")
      else
        prefix = (0..(depth*4)).map{|d| "&nbsp;"}.join
        s = account.id == selected ? "selected='selected'" : ""
        return (account.branch_edge ? "<option value='#{account.id}' #{s} class='depth-#{depth}'>#{prefix}#{account.name} <b>#{account.branch.name if account.branch}</b></option>" : "")
      end
    end

    def show_accounts_selector(accounts, selected = nil)
      rv = ""
      if accounts
        accounts.sort_by{|account_type, accounts| account_type.name}.each do |account_type, as|
          if as
            as.each do |account|
              rv += show_accounts(account, 0, 'select')
            end
          end
        end
      end
      return rv
    end



  end
end # Merb
