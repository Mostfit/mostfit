# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')


namespace :accounts do
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
end

