DEFAULT_JOURNAL_TYPES = ['Payment','Receipt','Journal']
INSTALLMENT_FREQUENCIES = [:daily, :weekly, :biweekly, :monthly]
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
