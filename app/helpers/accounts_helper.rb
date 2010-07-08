module Merb
  module AccountsHelper
    def show_child_accounts(account, depth=1)      
      children = account.children
      return show_row(account, depth) if children.length==0
      while(children.length>0)
        html = show_row(account, depth)
        return html + (children.collect do |child|
          show_child_accounts(child, depth+1)
        end).join
      end
    end
    
    private
    def show_row(account, depth)
      str = "<tr><td></td>"
      space  = ""
      depth.times{|x|
        space+= "&nbsp;&nbsp;&nbsp;&nbsp;"
      }
      str+= "  <td>"
      str+= "    #{space}#{link_to(account.name, resource(account))} "
      str+= "  </td>"
      str+= "  <td>"
      str+= "    #{account.gl_code}"
      str+= "  </td>"
      str+= "  <td>"
      str+= "    #{account.branch.name if account.branch}"
      str+= "  </td>"
      str+= "</tr>"
      str
    end
  end
end # Merb
