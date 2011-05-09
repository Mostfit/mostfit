if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "Save end-of-period balances for past accounting periods, optionally supply a date"
  task :save_account_balances do |task, args|
    previous_periods = AccountingPeriod.get_all_previous_periods
    if (previous_periods && previous_periods.size > 0)
      previous_periods.each do |period|
        period_balances = period.account_balances
        existing_accounts = period_balances.map {|bal| bal.account }
        applicable_accounts = Account.all(:opening_balance_on_date.lt => period.end_date)
        accounts_without_balances = applicable_accounts - existing_accounts
        puts "Balances already saved for all accounts for #{period.to_s}" if accounts_without_balances.empty?
        accounts_without_balances.each do |account|
          opening_balance = account.opening_balance_as_of period.begin_date
          closing_balance = account.closing_balance_as_of period.end_date
          balance_saved = AccountBalance.create(:opening_balance => opening_balance, :closing_balance => closing_balance, :account_id => account.id, :accounting_period_id => period.id, :created_at => DateTime.now)
          puts "Balance saved now for #{account.name} for #{period.to_s}" if balance_saved
        end
      end
    end
  end
end