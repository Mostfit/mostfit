INSTALLMENT_FREQUENCIES = [:daily, :weekly, :biweekly, :monthly]
STATUSES = [:applied_in_future, :pending_approval, :rejected, :approved, :disbursed, :outstanding, :repaid, :written_off, :claim_settlement]
EPSILON  = 0.001
INACTIVE_REASONS = ['', 'no_further_loans', 'death_of_client', 'death_of_spouse']
ModelsWithDocuments = ['Area', 'Region', 'Branch', 'Center', 'Client', 'Loan', 'ClientGroup', 'StaffMember', 'User', 'Mfi', 'Funder', 'InsuranceCompany', 'InsurancePolicy', 'Claim']
CLAIM_DOCUMENTS = [:death_certificate, :center_declaration_form, :kyc_document]
LOANS_NOT_PAYABLE = [nil, :repaid, :pending, :written_off, :claim_settlement]
DUMP_FOLDER      = "db/daily"
