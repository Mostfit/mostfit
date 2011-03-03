class CashBook < DayBook

  def generate
    day_entries = super
    cash_entries = {}
    day_entries.each do |branch, account_change|
      cash_entries[branch] = {} if cash_entries[branch].nil?
      account_change.each do |account, change|
        cash_entries[branch][account] = change if account.is_cash_account?
      end
    end
    cash_entries.delete_if {|key, value| cash_entries[key].empty? }
    cash_entries.sort
  end

  def name
    "Cash book for #{date}"
  end

  def self.name
    "Cash book"
  end
  
end