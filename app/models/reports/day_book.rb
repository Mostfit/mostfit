class DayBook < Report
  attr_accessor :date

  def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @name = "Day book as on #{@date}"
    get_parameters(params, user)
  end

  def generate
    date_params = {:date => date}
    journals_on_date = Journal.all(date_params)
    postings_on_date = []
    accounts_hit = []
    journals_on_date.each do |journal|
        journal.postings.each do |posting|
          postings_on_date << posting
          accounts_hit << Account.get(posting.account_id)
        end
    end
    uniq_accounts_hit = accounts_hit.uniq
    day_entries = {}
    uniq_accounts_hit.each do |account|
      day_entries[account] = 0
      postings_on_date.each do |posting|
        day_entries[account] += posting.amount if (posting.account_id == account.id) #currently ignores currency
      end
    end
    day_entries
  end

  def name
    "Day book for #{date}"
  end

  def self.name
    "Day book"
  end

end