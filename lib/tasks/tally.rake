require "rubygems"
require 'iconv'
require 'hpricot'

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace :mostfit do
  namespace :tally do
    def get_account_type(name)
      name = name.downcase
      if name.include?("assets") or name.include?("investment") or name.include?("capital account") 
        AccountType.first(:name => "Assets")
      elsif name.include?("expense") or name.include?("purchase") or name.include?("expenditure") or name.include?("salary")
        AccountType.first(:name => "Expenditure")
      elsif name.include?("liabilit") or name.include?("suspense")
        AccountType.first(:name => "Liabilities")
      elsif name.include?("income") or name.include?("sales account")
        AccountType.first(:name => "Income")
      else
        AccountType.first(:name => "Others")
      end
    end
    desc "Create accounts from tally XML dump"    
    task :coa_import do
      doc = Hpricot(Iconv.iconv("LATIN1", "UTF-16", File.read(ARGV[1]))[0])
      
      accounts = {}
      (doc/"envelope/body/importdata/requestdata/tallymessage/group").each{|x| 
        a = x.attributes["NAME"]
        if (x/"parent").inner_text.length==0
          Account.create(:name => a, :gl_code => a, :account_type => get_account_type(a))
        else          
          parent = Account.first(:name => (x/"parent").inner_text)
          Account.create(:name => a, :gl_code => a, :parent => parent, :account_type => parent.account_type)
        end
      }
      
      (doc/"envelope/body/importdata/requestdata/tallymessage/ledger").each{|x| 
        if (x/"parent").inner_text.length==0
          Account.create(:name => x.attributes["NAME"], :gl_code => x.attributes["NAME"], :account_type => get_account_type(x.attributes["NAME"]))
        else
          parent = Account.first(:name => (x/"parent").inner_text)
          if not parent
            p x
            p (x/"parent").inner_text
          end
          Account.create(:parent => parent, :name => x.attributes["NAME"], :gl_code => x.attributes["NAME"],
                         :account_type => parent.account_type)
        end
      }      
    end

    desc "Create Voucher XML dump for Tally"    
    task :voucher_download do
     
      Journal.xml_tally({})
    end
  end
end
