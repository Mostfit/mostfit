DEFAULT_JOURNAL_TYPES = ['Payment','Receipt','Journal']
INSTALLMENT_FREQUENCIES = [:daily, :weekly, :biweekly, :monthly, :quadweekly]
WEEKDAYS = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
STATUSES = [:applied_in_future, :pending_approval, :rejected, :approved, :disbursed, :outstanding, :repaid, :written_off, :claim_settlement]
EPSILON  = 0.001
INACTIVE_REASONS = ['', 'no_further_loans', 'death_of_client', 'death_of_spouse']
ModelsWithDocuments = ['Area', 'Region', 'Branch', 'Center', 'Client', 'Loan', 'ClientGroup', 'StaffMember', 'User', 'Mfi', 'Funder', 
                       'InsuranceCompany', 'InsurancePolicy', 'Claim']
CLAIM_DOCUMENTS = [:death_certificate, :center_declaration_form, :kyc_document]
LOANS_NOT_PAYABLE = [nil, :repaid, :pending, :written_off, :claim_settlement]
DUMP_FOLDER      = "db/daily"
MASS_ENTRY_FIELDS = {
  :client => [:spouse_name, :account_number, :type_of_account, :bank_name, :bank_branch, :join_holder, :number_of_family_members, 
              :school_distance, :phc_distance, :member_literate, :husband_litrate, :other_productive_asset, :income_regular, :client_migration, 
              :pr_loan_amount, :other_income, :total_income, :poverty_status, :children_girls_under_5_years, :children_girls_5_to_15_years, 
              :children_girls_over_15_years, :children_sons_under_5_years, :children_sons_5_to_15_years, :children_sons_over_15_years, 
              :not_in_school_working_girls, :not_in_school_bonded_girls, :not_in_school_working_sons, :not_in_school_bonded_sons, 
              :irrigated_land_own_fertile, :irrigated_land_leased_fertile, :irrigated_land_shared_fertile, :irrigated_land_own_semifertile, 
              :irrigated_land_leased_semifertile, :irrigated_land_shared_semifertile, :irrigated_land_own_wasteland, 
              :irrigated_land_leased_wasteland, :irrigated_land_shared_wasteland, :not_irrigated_land_own_fertile, 
              :not_irrigated_land_leased_fertile, :not_irrigated_land_shared_fertile, :not_irrigated_land_own_semifertile, 
              :not_irrigated_land_leased_semifertile, :not_irrigated_land_shared_semifertile, :not_irrigated_land_own_wasteland, 
              :not_irrigated_land_leased_wasteland, :not_irrigated_land_shared_wasteland, :caste, :religion, :occupation, 
              :client_type], 
  :loan => [:loan_utilization, :purpose]
}
CLEANER_INTERVAL = 120
FUNDER_ACCESSIBLE_REPORTS = ["ConsolidatedReport", "GroupConsolidatedReport", "StaffConsolidatedReport", "RepaymentOverdue"]
INFINITY  = 1.0/0
REPORT_ACCESS_HASH = {
  "TransactionLedger" =>        ["data_entry", "mis_manager", "admin", "read_only", "staff_member", "accountant"],
  "LoanDisbursementRegister" => ["data_entry", "mis_manager", "admin", "read_only", "staff_member", "accountant"], 
  "IncentiveReport"          => ["mis_manager", "admin", "read_only"],
  "WeeklyReport"             => ["mis_manager", "admin", "read_only", "staff_member", "funder", "accountant"], 
  "LateDisbursalsReport"     => ["data_entry", "mis_manager", "admin", "read_only", "staff_member", "accountant"],
  "ParByLoanAgeingReport"    => ["mis_manager", "admin", "read_only", "staff_member"], 
  "GroupConsolidatedReport"  => ["mis_manager", "admin", "read_only", "staff_member"],
  "ParByCenterReport"        => ["mis_manager", "admin", "read_only", "staff_member", "accountant"], 
  "ProjectedReport"          => ["data_entry", "mis_manager", "admin", "read_only", "staff_member", "accountant"], 
  "RepaymentOverdue"         => ["mis_manager", "admin", "read_only", "staff_member"],
  "DailyReport"              => ["data_entry", "mis_manager", "admin", "read_only", "staff_member", "accountant"],
  "LoanPurposeReport"        => ["mis_manager", "admin", "read_only", "staff_member", "funder", "accountant"],
  "AggregateConsolidatedReport" => ["mis_manager", "admin", "read_only", "staff_member", "funder", "accountant"],
  "ClaimReport"             => ["data_entry", "mis_manager", "admin", "read_only", "staff_member", "accountant"],
  "TrialBalanceReport"      => ["admin", "accountant"], 
  "StaffConsolidatedReport" => ["mis_manager", "admin", "read_only", "staff_member", "funder", "accountant"],
  "ParByStaffReport"        => ["mis_manager", "admin", "read_only", "staff_member"], 
  "GeneralLedgerReport"     => ["admin", "accountant"], 
  "DayBook"                 => ["admin", "accountant"], 
  "BankBook"                => ["admin", "accountant"],
  "DelinquentLoanReport"    => ["mis_manager", "admin", "read_only", "staff_member"], 
  "NonDisbursedClientsAfterGroupRecognitionTest" => ["mis_manager", "admin", "read_only", "staff_member"],
  "ClosedLoanReport"       => ["mis_manager", "admin", "read_only", "staff_member", "accountant"],
  "StaffTargetReport"      => ["mis_manager", "admin", "read_only", "staff_member"], 
  "CashBook"               => ["admin", "accountant"],
  "DailyTransactionSummary" => ["mis_manager", "admin", "read_only", "staff_member", "funder", "accountant"],
  "ConsolidatedReport"     => ["mis_manager", "admin", "read_only", "staff_member", "funder", "accountant"], 
  "ScheduledDisbursementRegister" => ["data_entry", "mis_manager", "admin", "read_only", "staff_member", "accountant"],
  "QuarterConsolidatedReport" => ["mis_manager", "admin", "read_only", "staff_member", "accountant"], 
  "InsuranceRegister"      => ["mis_manager", "admin", "read_only", "staff_member", "accountant"], 
  "TargetReport"           => ["mis_manager", "admin", "read_only", "staff_member"], 
  "ClientAbsenteeismReport"=> ["mis_manager", "admin", "read_only", "staff_member"], 
  "DuplicateClientsReport" => ["mis_manager", "admin", "read_only", "staff_member"], 
  "LoanSanctionRegister"   => ["data_entry", "mis_manager", "admin", "read_only", "staff_member", "accountant"], 
  "LoanSizePerManagerReport" => ["mis_manager", "admin", "read_only"], 
  "ClientOccupationReport" => ["mis_manager", "admin", "read_only"]
}
