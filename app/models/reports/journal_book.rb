class JournalBook < Report

  attr_accessor :date, :branch_id
  DATE_RANGE = 3

  def initialize(params, dates, user)
    @date = (dates and dates[:date] and not (dates[:date] == "")) ? dates[:date] : Date.today
    @branch_id = (params and params.key?(:branch_id) and not (params[:branch_id] == "")) ? params[:branch_id] : 0
    get_parameters(params, user)
  end
  
  def name
    "Journal for #{get_branch_name(@branch_id)} from #{@date} to #{(@date - 3)}"
  end
  
  def self.name
    "Journal"
  end

  def get_branch_name(branch_id)
    return "" unless branch_id
    return "Head Office" if branch_id == 0
    branch = Branch.get(branch_id)
    branch ? branch.name : ""
  end
  
  def generate
    data = {}
    from_date = @date - DATE_RANGE
    journals_by_date = {}
    from_date.upto(@date) {|dt| journals_by_date[dt] = []}
    journals = Journal.all(:date.gte => from_date, :date.lte => @date, :order => [:date.desc])
    journals.each do |j|
      journals_on_date = journals_by_date[j.date]
      j.postings.each do |p|
        account = p.account
        journals_on_date.push(j) if (account and (account.branch_id == @branch_id))
      end
    end
    data[:journals_by_date] = journals_by_date
    p data
    data
  end

end
