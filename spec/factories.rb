require 'factory_girl'

FACTORY_NAMES       = %w[Smith Anderson Rodriguez Gonzalez Campbell Parker Moore Helen Donald Richard Dick Deborah].freeze
FACTORY_PLACES      = %w[Mumbai Hyderabad Pune Bangalore Cochin Chennai Kolkata].freeze
FACTORY_HOLIDAYS    = %w[Diwali Holi Pongal Dussehra].freeze
FACTORY_OCCUPATIONS = %w[Carpenter Astrologer Engineer Teller Cook Butcher Actuary Executive Artist].freeze
FACTORY_PROVINCES   = ['Maharashtra', 'Andra Pradesh', 'Madhya Pradesh', 'Kerala', 'Tamil Nadu'].freeze
FACTORY_PURPOSES    = ['Buying a boat', 'Christmas presents', 'Wife\'s birthday'].freeze
FACTORY_ASSETS      = ['Laptop charger', 'Laser printer', 'Mobile phone', 'Airconditioner'].freeze

FactoryGirl.define do

  # General sequences
  sequence(:name)               { |n| [FACTORY_NAMES[n%FACTORY_NAMES.length], n.to_s].join(' ') }
  sequence(:email)              { |n| [FACTORY_NAMES[n%FACTORY_NAMES.length], n.to_s, '@', FACTORY_PLACES[n%FACTORY_PLACES.length], '.in'].join.downcase }
  sequence(:city)               { |n| [FACTORY_PLACES[n%FACTORY_PLACES.length], "center", n.to_s].join(' ') }
  sequence(:province)           { |n| [FACTORY_PROVINCES[n%FACTORY_PROVINCES.length], n.to_s].join(' ') }
  # User related sequences
  sequence(:user_login)         { |n| "user_#{n}" }
  # Branch sequences
  sequence(:branch_code)        { |n| "BR#{n}" }
  # Center sequences
  sequence(:center_code)        { |n| "CEN#{n}" }
  # ClientGroup sequences
  sequence(:group_name)         { |n| "Group #{n}" }
  sequence(:group_code)         { |n| "G#{n}" }
  # Loan sequences
  sequence(:loan_product_name)  { |n| "Loan product #{n}" }
  sequence(:loan_purpose)       { |n| [FACTORY_PURPOSES[n%FACTORY_PURPOSES.length], n.to_s].join(' ') }
  # Fee sequences
  sequence(:fee_name)           { |n| "Fee #{n}" }
  # Account sequences
  sequence(:account_name)       { |n| "Account #{n}" }
  sequence(:account_gl_code)    { |n| "GL#{n}" }
  sequence(:account_type_name)  { |n| "Account Type #{n}" }
  sequence(:account_type_code)  { |n| "AT#{n}" }
  # Holiday sequences
  sequence(:holiday_name)       { |n| [FACTORY_HOLIDAYS[n%FACTORY_HOLIDAYS.length], n.to_s].join(' ') }
  # Occupations
  sequence(:occupation)         { |n| [FACTORY_OCCUPATIONS[n%FACTORY_OCCUPATIONS.length], n.to_s].join(' ') }
  sequence(:occupation_code)    { |n| "OCC#{n}" }
  # Assets
  sequence(:asset_type)         { |n| [FACTORY_ASSETS[n%FACTORY_ASSETS.length], n.to_s].join(' ') }

  #
  # Organizations, Domains, MFIs
  #
  factory :organization do
    name            { "#{Factory.next(:name)}'s Organization" }
  end

  factory :domain do
    name            { "#{Factory.next(:name)}'s Domain" }
    association     :organization
  end

  # This one is failing because DataMapper::Adapters::AbstractAdapter#create not implemented (?)
  factory :mfi do
    email           { Factory.next(:email) }
    address         '101, Shrinathji, 15th Cross Road, Khar (W), Mumbai-52'
    telephone       '06-123123123'
  end

  #
  # Users, StaffMembers, Clients, Funders, Guarantors
  #
  factory :user do
    login                 { Factory.next(:user_login) }
    password              'secret'
    password_confirmation 'secret'
    role                  'staff_member'
    active                true
  end

  factory :staff_member do
    name            { Factory.next(:name) }
    mobile_number   '06-123123123'
    active          true
  end

  factory :funder do
    name            { Factory.next(:name) }
  end

  factory :guarantor do
    name            { Factory.next(:name) }
    gender          'male'
    father_name     { Factory.next(:name) }
    association     :client
  end

  factory :client do
    reference       { "XW000-2009.01.05.#{Time.new.usec}" }
    name            { Factory.next(:name) }
    active          true
    gender          'male'
    date_joined     { Date.parse('2000-01-01') }

    association     :client_type
    association     :center
    association     :created_by, :factory => :user
    association     :created_by_staff, :factory => :staff_member
  end

  factory :client_type do
    type            "Standard client"
  end

  factory :client_group do
    name            { Factory.next(:group_name) }
    code            { Factory.next(:group_code) }

    association     :center
    association     :created_by_staff, :factory => :staff_member
  end

  factory :occupation do
    name            { Factory.next(:occupation) }
    code            { Factory.next(:occupation_code) }
  end

  #
  # Targets
  #
  factory :target do
    target_value    1000
    start_value     100
    target_of       'center_creation'
    target_type     'absolute'
    deadline        { Date.today + 60 }
    start_date      { Date.today - 60 }
    attached_to     :center
    attached_id     { Factory(:center).id }
  end

  factory :monthly_target do
    for_month       { Date.today }
    association     :staff_member
  end

  #
  # Holidays
  #
  factory :holiday do
    name            { Factory.next(:holiday_name) }
    date            { Date.today }
    shift_meeting   :after
  end

  factory :holiday_calendar do
    association     :branch
  end

  factory :holidays_for do
    association     :holiday
    association     :holiday_calendar
  end

  #
  # Branches, Centers, Areas, Regions, AssetRegisters, Attendances
  #
  factory :branch do
    name            { Factory.next(:city) }
    code            { Factory.next(:branch_code) }

    association     :manager, :factory => :staff_member
  end

  factory :branch_diary do
    opening_time_hours    8
    opening_time_minutes  0
    branch_key            { self.branch.id }
    association           :manager, :factory => :staff_member
    association           :branch
  end

  factory :center do
    name            { Factory.next(:province) }
    code            { Factory.next(:center_code) }
    meeting_day     :wednesday

    association     :branch
    association     :manager, :factory => :staff_member
  end

  factory :center_leader do
    date_assigned   { Date.today }
    association     :center
    association     :client
  end

  factory :center_meeting_day do
    valid_from      { Date.today }
    association :center
  end

  factory :location do
    parent_id       { Factory(:area).id }
    parent_type     'Area'
    latitude        18.5026756
    longitude       73.9267069
  end

  factory :area do
    name            { Factory.next(:city) }
    association     :manager, :factory => :staff_member
    association     :region
  end

  factory :region do
    name            { Factory.next(:province) }
    association     :manager, :factory => :staff_member
  end

  factory :asset_register do
    name            { Factory.next(:name) }
    asset_type      { Factory.next(:asset_type) }
    association     :manager, :factory => :staff_member
  end

  factory :attendance do
    date            { Date.today }
    status          'present'
    association     :client
    association     :center
  end

  #
  # Loans, Products, Accrual, Fees
  #
  factory :loan do
    amount                        1000
    interest_rate                 0.20
    installment_frequency         :weekly
    number_of_installments        25
    applied_on                    { Date.new(2000,02,01) }
    scheduled_disbursal_date      { Date.new(2000,06,13) }
    scheduled_first_payment_date  { Date.new(2000,12,06) }
    history_disabled              true

    association                   :applied_by, :factory => :staff_member
    association                   :funding_line
    association                   :client
    association                   :loan_product
    association                   :repayment_style

    # These cached properties should probably be set automatically somewhere?
    c_center_id                   { self.client.center.id }
    c_branch_id                   { self.client.center.branch.id }
  end

  # This is a variation of the minimal :loan factory, representing a recently disbursed loan.
  # It includes disbursal dates and other attributes necessary to make
  # the loan work with the :payment factory and others.
  factory :disbursed_loan, :parent => :loan do
    approved_by                   { self.applied_by }
    approved_on                   { Date.today - 20 }
    scheduled_disbursal_date      { Date.today - 10 }
    disbursal_date                { Date.today - 10 }
    scheduled_first_payment_date  { Date.today + 10 }
    disbursed_by                  { self.applied_by }
  end

  factory :loan_product do
    name                        { Factory.next(:loan_product_name) }
    min_amount                  1000
    max_amount                  10000
    max_interest_rate           100
    min_interest_rate           0.1
    installment_frequency       :weekly
    min_number_of_installments  1
    max_number_of_installments  125
    # loan_type                   "DefaultLoan" # <= property was commented out in the model but still used in the tests
    valid_from                  { Date.parse('2000-01-01') }
    valid_upto                  { Date.parse('2012-01-01') }

    association                 :repayment_style
  end

  factory :loan_history do
    scheduled_outstanding_total       15000
    scheduled_outstanding_principal   10000
    actual_outstanding_total          15000
    actual_outstanding_principal      10000
    actual_outstanding_interest       5000
    scheduled_principal_due           1000
    scheduled_interest_due            500
    principal_due                     1000
    interest_due                      500
    principal_paid                    5000
    interest_paid                     2500
    total_principal_due               10000
    total_interest_due                5000
    total_principal_paid              5000
    total_interest_paid               2500
    advance_principal_paid            1000
    advance_interest_paid             500
    total_advance_paid                2500
    advance_principal_paid_today      500
    advance_interest_paid_today       500
    total_advance_paid_today          500
    advance_principal_adjusted        2500
    advance_interest_adjusted         500
    advance_principal_adjusted_today  1000
    advance_interest_adjusted_today   500
    total_advance_adjusted_today      1000
    advance_principal_outstanding     1000
    advance_interest_outstanding      1000
    total_advance_outstanding         1000
    principal_in_default              2500
    interest_in_default               500
    total_fees_due                    10000
    total_fees_paid                   5000
    fees_due_today                    500
    fees_paid_today                   500
    principal_at_risk                 10000

    date                              { Date.today }
    status                            STATUSES.first
    last_status                       STATUSES.last
    association                       :loan
  end

  factory :loan_purpose do
    name                { Factory.next(:loan_purpose) }
  end

  factory :loan_type do
    installment_frequency :daily
  end

  factory :loan_utilization do
    name                'Loan Utilization'
  end

  factory :dirty_loan do
    association         :loan
  end

  # Note validations will bork if no Mfi records are available. Missing 'received_on' will
  # result in a raised error in #not_received_in_the_future? instead of a validation failure
  factory :payment do
    amount              100
    type                :principal
    created_at          { Date.today }
    received_on         { Date.today }
    association         :created_by, :factory => :user
    association         :received_by, :factory => :staff_member
    association         :client

    association         :loan, :factory => :disbursed_loan

    # It feels like these properties should be assigned automatically on creation or something?
    c_center_id         { self.client.center.id }
    c_branch_id         { self.client.center.branch.id }
  end

  factory :repayment_style do
    name                'EquatedWeekly'
    style               'EquatedWeekly'
    rounding_style      'round' # Took me forever to figure this one out but if we don't specify a rounding style loans will bork badly
    round_total_to      1
    round_interest_to   1
  end

  factory :funding_line do
    amount              10_000_000
    interest_rate       0.15
    disbursal_date      '2006-02-02'
    first_payment_date  '2007-05-05'
    last_payment_date   '2009-03-03'
    association         :funder
  end

  factory :accrual do
    amount              100
    currency            'INR'
    accrual_type        'interest_receivable'
    accrue_from_date    { Date.today }
    accrue_till_date    { Date.today + 365 }
    accrue_on_date      { Date.today + 182 }
    association         :created_by, :factory => :user
  end

  factory :fee do
    name                { Factory.next(:fee_name) }
    payable_on          'loan_applied_on'
    rounding_style      'round'
    amount              100
  end

  factory :applicable_fee do
    amount              100
    applicable_type     'Loan'
    applicable_id       { Factory(:loan).id }
    association         :fee
  end

  #
  # Portfolios
  #
  factory :portfolio do
    name                { "#{Factory.next(:name)}'s Portfolio"[0...20] }
    association         :created_by, :factory => :user
    association         :funder
  end

  factory :portfolio_loan do
    original_value      1000
    starting_value      500
    current_value       100
    association         :portfolio
    association         :loan
  end

  #
  # Accounts, Balances, Postings
  #
  factory :account do
    name                { Factory.next(:account_name) }
    gl_code             { Factory.next(:account_gl_code) }
    association         :account_type
  end

  factory :account_balance do
    association         :accounting_period
    association         :account
  end

  factory :account_type do
    name                { Factory.next(:account_type_name) }
    code                { Factory.next(:account_type_code) }
  end

  factory :accounting_period do
  end

  factory :posting do
    action              'principal'

    association         :account
    association         :journal
    association         :currency
  end

  #
  # Rules and Conditions
  #
  # This factory fails occasionally with error "nil", which I'm guessing is caused by #apply_rule
  factory :rule do
    name                { Factory.next(:name) }
    model_name          'Loan'
    condition           'A condition!'
    on_action           'create'
    permit              true
  end

  factory :condition do
    keys                'amount'
    comparator          :<
    value               '10'

    association         :rule
  end

  factory :predicate do
    condition_type      'condition'
    operator            'equal'
    association         :rule
  end

  #
  # Account rules
  #
  # Note this factory fails when called by itself, it requires one or more credit and debit
  # account rules whose percentages total up to 100% each.
  factory :rule_book do
    name                { Factory.next(:name) }
    action              'principal'
    association         :journal_type
    association         :created_by, :factory => :user
  end

  # These factories do work, but the associatied rule_book won't be valid untill both debit
  # and credit_account rules are added. I don't think FactoryGirl validates associated objects.
  factory :credit_account_rule do
    percentage          100
    association         :rule_book
    association         :credit_account, :factory => :account
  end

  factory :debit_account_rule do
    percentage          100
    association         :rule_book
    association         :debit_account, :factory => :account
  end

  #
  # Ledgers
  #
  factory :ledger_entry do
    transaction         :credit
  end

  #
  # Batches and Journals
  #
  factory :batch do
    creation_time       { Time.now }
  end

  factory :journal do
    association         :verified_by, :factory => :user
    association         :journal_type
  end

  factory :journal_type do
  end

  #
  # Insurance
  #
  factory :insurance_company do
    name                { "#{Factory.next(:name)}'s InsuranceCompany" }
  end

  factory :insurance_product do
    association         :insurance_company
  end

  factory :insurance_policy do
    sum_insured         10000
    premium             1000
    date_from           { Date.today - 30 }
    date_to             { Date.today + 30 }
    status              'active'
    association         :client
    association         :insurance_product
  end

  #
  # WeekSheets
  #
  factory :weeksheet do
  end

  factory :weeksheet_row do
    association :weeksheet
  end

  #
  # Reporting
  #
  factory :report do
  end

  factory :report_format do
  end

  #
  # Other models
  #
  factory :api_access do
    origin              { Factory.next(:name) }
    description         'An api_access record to test with'
    association         :branch
  end

  factory :audit_item do
    audited_model       'Branch'
    audited_id          { Factory(:branch).id }
    due_on              { Date.today + 1 }
    association         :assigned_to, :factory => :staff_member
  end

  factory :audit_trail do
    audited_model       'Branch'
    audited_id          { Factory(:branch).id }
  end

  factory :bookmark do
    name                'home'
    title               'Home page'
    route               '/'
    type                BookmarkTypes.first
    share_with          User::ROLES.first

    association         :user
  end

  factory :claim do
    date_of_death       { Date.today }
    claim_id            '201001011'
    association         :client, :active => false
  end

  factory :comment do
    association         :user
  end

  factory :currency do
    name                'INR'
  end

  factory :document do
    parent_model        'Branch'
    parent_id           { Factory(:branch).id }
    association         :document_type
  end

  factory :document_type do
    parent_model        'Branch'
    parent_id           { Factory(:branch).id }
  end

  factory :stock_register do
    stock_code          'SC01'
    bill_number         '12345'
    bill_date           { Date.today }

    association         :manager, :factory => :staff_member
    association         :branch
  end

  # What the heck is this?
  factory :extended_info_item do
  end

  factory :transaction_log do
    update_type           'create'
    txn_type              'receipt'
    nature_of_transaction 'principal_received'
    currency              'INR'
    paid_by_type          'User'
    paid_by_id            { Factory(:user).id }
    received_by_type      'StaffMember'
    received_by_id        { Factory(:staff_member).id }
    transacted_at_type    'Center'
  end

  # Dunno what this is either..
  factory :grt do
    date                  { Date.today }
    status                'Passed'

    association           :client_group
  end

end
