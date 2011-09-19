--this sql script will modify some fields of loan_history-----

alter table loan_history modify scheduled_principal_due float;
alter table loan_history modify scheduled_interest_due float;
alter table loan_history modify advance_principal_paid float;
alter table loan_history modify advance_interest_paid float;
alter table loan_history modify total_advance_paid float;
alter table loan_history modify advance_principal_paid_today float;
alter table loan_history modify advance_interest_paid_today float;
alter table loan_history modify total_advance_paid_today float;
alter table loan_history modify advance_principal_adjusted float;
alter table loan_history modify advance_interest_adjusted float;
alter table loan_history modify principal_in_default float;
alter table loan_history modify interest_in_default float;
alter table loan_history modify total_fees_due float;
alter table loan_history modify total_fees_paid float;
alter table loan_history modify fees_due_today float;
alter table loan_history modify fees_paid_today float;