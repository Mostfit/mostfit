Merb.logger.info("Compiling business rules...")


Mostfit::Business::Rules.add :name => :number_of_branches_in_area,  :model_name => Branch, :on_action => :create, :condition => ["area.branches.count", :less_than_equal,  2]

Mostfit::Business::Rules.add :name => :max_centers_in_area,        :model_name => Center, :on_action => :create, 
            :condition => [:not, ["branch.area.branches.centers.count", :greater_than_equal, 100]]

Mostfit::Business::Rules.add  :name => :max_centers_in_branch,       :model_name => Loan,   :on_action => :create, :condition =>  ["client.center.branch.centers.count", :less_than_equal, 50]


Mostfit::Business::Rules.add  :name => :min_centers_and_clients_in_branch,       :model_name => Loan,   :on_action => :create,
            :condition => [ :and , ["client.center.branch.centers.count", :greater_than_equal, 0] ,
             ["client.center.branch.centers.clients.count", :greater_than_equal, 0] ]

# Mostfit::Business::Rules.prepare do |rule|
##does not work as of now
#  rule.add :name => :loans_more_than_10k,         :model_name => Loan,   :on_action => :save,
#             :condition => [ :and, [ :and,  [:disbursal_date, :not, nil], [:amount, :greater_than_equal, 10000]], [:disbursed_by, :equal, "client.center.branch.manager"] ]
#
#
#  rule.allow  :name => :min_centers_in_branch,       :model_name => Loan,   :on_action => :create,  :condition => ["client.center.branch.centers.count", :greater_than_equal, 5]
#  rule.allow  :name => :min_clients_in_branch,       :model_name => Loan,   :on_action => :create,  
#              :condition => ["client.center.branch.centers.clients.count", :greater_than_equal, 5]
#
#  rule.allow  :name => :deletion_of_loan,           :model_name => Loan,   :on_action => :destroy, :condition => ["payments.count", :greater_than_equal, 1]
#  rule.allow  :name => :deletion_of_client,         :model_name => Client, :on_action => :destroy, :condition => ["loans.count", :greater_than_equal, 1]
#  rule.reject :name => :deletion_of_center,         :model_name => Center, :on_action => :destroy, :condition => ["clients.loans.count", :greater_than_equal, 1]
#  rule.reject :name => :deletion_of_branch,         :model_name => Branch, :on_action => :destroy, :condition => ["centers.clients.loans.count", :greater_than_equal, 1]
#
#  rule.reject :name => :amount_under_a_branch,      :model_name => Loan, :on_action => :save,
##   :precondition => [:disbursal_date, :not_equal, nil], 
#              :condition => ["client.center.branch.centers.clients.loans.sum(:amount)", :less_than_equal, 1000000]
#  rule.reject :name => :number_of_loans_per_day,    :model_name => Loan, :on_action => :save,
##    :precondition => [:disbursal_date, :not_equal, nil],
#              :condition => ["client.center.branch.centers.clients.loans.sum(:amount)", :less_than_equal, 1000000]
#end
