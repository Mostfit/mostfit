class LoanAgeingAnalysis < Report
  include Mostfit::Reporting

  attr_accessor :date
  attr_reader :data

  validates_with_method :date, :date_should_not_be_in_future

  column :overdue_by
  column :total_loan_amount
  column :total_outstanding_principal
  column :outstanding_as_percentage_of_total_outstanding
  column :total_PAR
  column :provisioning_percentage
  column :loan_loss_provision

  def initialize(params, dates, user)
    @date = dates[:date]|| Date.today
  end

  def name
    "Loan Ageing Analysis as on #{@date}"
  end

  def self.name
    "Loan Ageing Analysis"
  end

  def generate
    data = {}
    selects = ["l.amount amount", :actual_outstanding_principal, :days_overdue]
    # TODO: find a way to query this so we get it for the entire organization
    # TODO: if :branch is used as the first argument below, the data does not
    # return loans that are not overdue. In fact, not sure if it always returns loans that are not overdue
    par_data_grouped = LoanHistory.defaulted_loan_info_by(:center, @date,  {}, selects).group_by{|lh| lh.days_overdue}
    days_overdue_list = par_data_grouped.keys.sort
    buckets = []
    total_outstanding = 0.0; total_provisioning = 0.0
    LOAN_AGEING_BUCKETS.each do |bucket_limit|
      row = {}
      buckets << bucket_limit if bucket_limit.is_a?(Fixnum)
      
      if bucket_limit.is_a?(Symbol)
        prev_bucket = buckets.last
        days_range = days_overdue_list.select {|days| prev_bucket < days}
      elsif bucket_limit > 0
        prev_bucket = buckets[buckets.index(bucket_limit) - 1]
        days_range = days_overdue_list.select {|days| prev_bucket < days && days <= bucket_limit}
      else
        days_range = [0]
      end

      loan_amounts = 0.0; loan_outstanding_principal = 0.0
      days_range.each do |days|
        overdue_loans = par_data_grouped[days]
        if overdue_loans
          loan_amounts = overdue_loans.inject(loan_amounts) {|loan_amounts, loans| loan_amounts + loans.amount}
          loan_outstanding_principal =
            overdue_loans.inject(loan_outstanding_principal) {|loan_outstanding_principal, loans| loan_outstanding_principal + loans.actual_outstanding_principal}
        end
      end
      total_outstanding += loan_outstanding_principal
      total_par = (bucket_limit == 0) ? 0.0 : loan_outstanding_principal
      provisioning_percentage = LOSS_PROVISION_PERCENTAGES_BY_BUCKET[LOAN_AGEING_BUCKETS.index(bucket_limit)]
      provisioning = (provisioning_percentage * total_par/100); total_provisioning += provisioning

      row[:total_loan_amount] = loan_amounts
      row[:total_outstanding_principal] = loan_outstanding_principal
      row[:provisioning_percentage] = provisioning_percentage
      row[:provisioning] = provisioning
      data[bucket_limit] = row
    end
    data.values.each do |row|
      percentage = (row[:total_outstanding_principal]/total_outstanding) * 100 if row[:total_outstanding_principal] && total_outstanding
      percentage = 0.0 if percentage.nan?
      row.merge!(:outstanding_as_percentage_of_total => percentage)
    end
    data[:total_provisioning] = total_provisioning
    @data = data
  end

end