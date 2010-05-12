Merb.logger.info("Compiling business rules...")
Merb::Business::Rule.prepare do |rule|
  rule.allow :name => :number_of_branches_in_area,  :model => Branch, :on => :create, :condition => ["area.branches.count", :less_than_equal,  5]
  rule.allow :name => :loans_more_than_10k,         :model => Loan,   :on => :save,   :if => {:disbursal_date.not => nil, :amount.gt => 10000}, :condition => {:disbursed_by => "client.center.branch.staff_member"}

  rule.reject :name => :max_centers_in_area,        :model => Center, :on => :create, :condition => ["branch.area.branches.centers.count", :greater_than_equal, 100]
  rule.allow :name => :max_centers_in_branch,       :model => Loan,   :on => :create, :condition => ["client.center.branch.centers.count", :less_than_equal, 50]

  rule.allow :name => :min_centers_in_branch,       :model => Loan,   :on => :create,  :condition => ["client.center.branch.centers.count", :greater_than_equal, 5]
  rule.allow :name => :min_clients_in_branch,       :model => Loan,   :on => :create,  :condition => ["client.center.branch.centers.clients.count", :greater_than_equal, 5]

  rule.allow  :name => :deletion_of_loan,           :model => Loan,   :on => :destroy, :condition => ["payments.count", :greater_than_equal, 1]
  rule.allow  :name => :deletion_of_client,         :model => Client, :on => :destroy, :condition => ["loans.count", :greater_than_equal, 1]
  rule.reject :name => :deletion_of_center,         :model => Center, :on => :destroy, :condition => [":clients.loans.count", :greater_than_equal, 1]
  rule.reject :name => :deletion_of_branch,         :model => Branch, :on => :destroy, :condition => ["centers.clients.loans.count", :greater_than_equal, 1]
  rule.reject :name => :deletion_of_branch,         :model => Branch, :on => :destroy, :condition => ["centers.clients.loans.count", :greater_than_equal, 1]

  rule.reject :name => :amount_under_a_branch,      :model => Loan, :on => :save, :if => {:disbursal_date.not => nil}, :condition => ["client.center.branch.centers.clients.loans.sum(:amount)", :less_than_equal, 1000000]
  rule.reject :name => :number_of_loans_per_day,    :model => Loan, :on => :save, :if => {:disbursal_date.not => nil}, :condition => ["client.center.branch.centers.clients.loans.sum(:amount)", :less_than_equal, 1000000]
end
