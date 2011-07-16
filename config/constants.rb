DEFAULT_JOURNAL_TYPES = ['Payment','Receipt','Journal']

CASH = 'Cash'; BANK_DEPOSITS = 'Bank Deposits'; SECURITIES = 'Securities'
LAND = 'Land'; MACHINERY = 'Machinery'
LOANS_MADE = 'Loans made'; BORROWINGS = 'Borrowings'; TAXES_PAYABLE = "Tax payable"; OTHER_LIABILITIES = "Other liabilities"
CURRENT_ASSET_HEADS = [CASH, BANK_DEPOSITS, SECURITIES, LOANS_MADE]
FIXED_ASSET_HEADS = [LAND, MACHINERY]
LIABILITIES = [BORROWINGS, TAXES_PAYABLE, OTHER_LIABILITIES]
ASSET_CLASS_NOT_CHOSEN = 'Choose asset or liability class'
ASSET_CLASSES = [CURRENT_ASSET_HEADS, FIXED_ASSET_HEADS, LIABILITIES].flatten
CAPITAL = "Capital"; RESERVES = "Reserves"; PROFIT_AND_LOSS_ACCOUNT = "Profit & Loss Account"
EQUITY = [CAPITAL, RESERVES, PROFIT_AND_LOSS_ACCOUNT]

INTEREST_INCOME = 'Interest Income'; INTEREST_EARNED_ON_DEPOSITS = 'Interest earned on deposits'; FEE_INCOME = 'Fee income'
INCOMES = [INTEREST_INCOME, INTEREST_EARNED_ON_DEPOSITS, FEE_INCOME]
SALARIES = 'Salaries'; RENT_AND_TAXES = 'Rent, Rates, and Taxes'; ADMIN_EXPENSES = 'Administration Expenses'; TRAVEL_EXPENSES = 'Travel And Conveyance';
EXPENSES = [SALARIES, RENT_AND_TAXES, ADMIN_EXPENSES, TRAVEL_EXPENSES]
INCOME_HEAD_NOT_CHOSEN = 'Choose income or expense head'
INCOME_HEADS = [INCOMES, EXPENSES].flatten

INSTALLMENT_FREQUENCIES = [:daily, :weekly, :biweekly, :monthly, :quadweekly]
WEEKDAYS = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
MONTHS = ["None", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
STATUSES = [:applied_in_future, :pending_approval, :rejected, :approved, :disbursed, :outstanding, :repaid, :written_off, :claim_settlement, :preclosed]
EPSILON  = 0.01
INACTIVE_REASONS = ['', 'no_further_loans', 'death_of_client', 'death_of_spouse']
ModelsWithDocuments = ['Area', 'Region', 'Branch', 'Center', 'Client', 'Loan', 'ClientGroup', 'StaffMember', 'User', 'Mfi', 'Funder', 
                       'InsuranceCompany', 'InsurancePolicy', 'Claim']
CLAIM_DOCUMENTS = [:death_certificate, :center_declaration_form, :kyc_document]
LOANS_NOT_PAYABLE = [nil, :repaid, :pending, :written_off, :claim_settlement, :preclosed]
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
  :loan => [:loan_utilization, :purpose, :funding_line]
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
NORMAL_REPAYMENT_STYLE = :normal
PRORATA_REPAYMENT_STYLE = :prorata
REPAYMENT_STYLES = [NORMAL_REPAYMENT_STYLE, PRORATA_REPAYMENT_STYLE]
API_SUPPORT_FORMAT = ["xml"]
LOAN_AGEING_BUCKETS = [0, 30, 60, 90, 180, 365, :older]
LOSS_PROVISION_PERCENTAGES_BY_BUCKET = [0, 10, 25, 50, 75, 90, 100]
DEFAULT_LOCALE = 'en'
LOCALES = [["en","English"],["hi","Hindi"]]
DEFAULT_ORIGIN = "server"
#Date format initializers
#PREFERED_DATE_PATTERNS = ["%d-%m-%y", "%m-%d-%y", "%y-%m-%d", "%y-%d-%m", "%d-%m-%Y", "%m-%d-%Y", "%Y-%m-%d", "%Y-%d-%m"]
PREFERED_DATE_PATTERNS = ["%m-%d-%Y", "%Y-%m-%d"]
PREFERED_DATE_SEPARATORS = { :hypen => "-", :slash => "/", :period => "." }
PREFERED_DATE_STYLES = [[:SHORT, "31-12-2001"],[:MEDIUM, "Dec 31, 2001"],[:LONG, "December 31, 2001"], [:FULL,"Monday, December 31, 2001"]]
DEFAULT_DATE_PATTERN = "%d-%m-%Y"
DEFAULT_DATE_SEPARATOR = "-"
DEFAULT_DATE_STYLE = "short"
MEDIUM_DATE_PATTERN = "%b %d, %Y"
LONG_DATE_PATTERN = "%B %d, %Y"
FULL_DATE_PATTERN = "%A, %B %d, %Y"
FORMAT_REG_EXP = /[- . \/]/

