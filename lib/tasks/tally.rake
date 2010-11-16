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
      require 'iconv'
      require 'nokogiri'
      str  = Iconv.iconv("LATIN1", "UTF-16", File.read(ARGV[1]))[0].downcase
      doc = Nokogiri(str)
      accounts = {}
      (doc.xpath("envelope/body/importdata/requestdata/tallymessage/group")).each{|x| 
        a = x.attributes["name"].value
        if (x.xpath("parent")).inner_text.length==0
          Account.create(:name => a, :gl_code => a, :account_type => get_account_type(a))
        else
          parent_name = x.xpath("parent").children.inner_text
          parent = Account.first(:name => parent_name)
          Account.create(:name => a, :gl_code => a, :parent => parent, :account_type => parent.account_type)
        end
      }
      
      (doc.xpath("envelope/body/importdata/requestdata/tallymessage/ledger")).each{|x| 
        if (x.xpath("parent")).inner_text.length==0
          name  = x.attributes["name"].value
          Account.create(:name => name, :gl_code => name, :account_type => get_account_type(name))
        else
          parent_name = x.xpath("parent").children.inner_text
          parent = Account.first(:name => parent_name)
          if not parent
            p x
            p x.xpath("parent")
          end
          name  = x.attributes["name"].value
          Account.create(:parent => parent, :name => name, :gl_code => name,
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
