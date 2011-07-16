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
  desc "recreate the ledgers"
  task :recreate_ledgers do
    puts "recreating ledgers"
    Loan.all.each do |l|
      if l.disbursal_date
        entry = LedgerEntry.create(:ledger_name => "cash", :transaction => :debit, :amount => l.amount,
                                :date => l.disbursal_date, :comment => "Loan id #{l.id} disbursed")
        entry = LedgerEntry.create(:ledger_name => "loans", :transaction => :credit, :date => l.disbursal_date,
                                   :comment => "Loan id #{l.id} disbursed", :amount => l.amount)
      end
    end
    Payment.all.each do |p|
      entry = LedgerEntry.create(:ledger_name => "principal", :transaction => :credit, :date => p.received_on,
                                 :comment => "principal for #{p.loan.id} received", :amount => p.principal)
      entry = LedgerEntry.create(:ledger_name => "interest", :transaction => :credit, :date => p.received_on,
                                 :comment => "interest for #{p.loan.id} received", :amount => p.interest)
      entry = LedgerEntry.create(:ledger_name => "cash", :transaction => :credit, :date => p.received_on,
                                 :comment => "payment for #{p.loan.id} received", :amount => (p.principal + p.interest))
      entry = LedgerEntry.create(:ledger_name => "loans", :transaction => :debit, :date => p.received_on,
                                 :comment => "principal for #{p.loan.id} received", :amount => p.principal)
    end
  end

  desc "Make account entries for previous Payments"
  task :recreate_payment_accounts do
    puts "Making account entries for Payments"
    ids = Branch.get(1).loans.payments(:received_on => Date.new(2011,06,8)).aggregate(:id)
    Payment.all(:id => ids).each_with_index do |p,i|
      puts "doing #{i} of #{ids.count}"
      AccountPaymentObserver.make_posting_entries(p)
    end
  end

  desc "Make account entries for previous Loans"
  task :recreate_loans_accounts do
    puts "Making account entries for Loans"
    Loan.all(:disbursal_date.not => nil).each do |l|
      AccountLoanObserver.make_posting_entries_on_update(l)
    end
  end

  desc "Migrating the Accounting Database to new style"
  task :accounts_migration_add_branch do
    parents_list = Account.all().map{|x| x.parent_id}.uniq
    parents_list.delete(nil)
    
    Account.all(:id.not => parents_list, :branch_id => nil).each{|x|
       x.branch_id = 0
       x.save
       }
    errors = []
    accounts = Account.all(:id => parents_list, :branch_id => nil)
    Branch.all.each{|branch|
      accounts.each{|account|
        account.id = nil 
        new_account = Account.new(account.attributes)
        new_account.branch = branch
        unless new_account.save
          new_account.valid?
          errors.push(new_account.errors)
          exit
        end
        child_accounts = account.children(:branch_id => branch.id)
        child_accounts.each{|child| 
          child.parent = Account.get(new_account.id)
          child.save
        }
      }
    }
  end

end

