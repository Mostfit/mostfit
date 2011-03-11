class BankBook < DayBook

  def generate
    day_entries = super
    bank_entries = {}
    day_entries.each do |branch, account_change|
      bank_entries[branch] = {} if bank_entries[branch].nil?
      account_change.each do |account, change|
        bank_entries[branch][account] = change if account.is_bank_account?
      end
    end
    bank_entries.delete_if {|key, value| bank_entries[key].empty? }
    bank_entries
  end

  def name
    "Bank book for #{date}"
  end

  def self.name
    "Bank book"
  end
  
end
