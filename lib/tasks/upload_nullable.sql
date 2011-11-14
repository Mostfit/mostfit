-- 
-- the new app/models/upload.rb defines has n, model relationships on all of the following: 
--   MODELS = [:staff_members, :repayment_styles, :loan_products, :funding_lines, :branches, :centers, :client_groups, :clients, :loans]
-- please run the below script first BEFORE rake db:autoupgrade or rake mostfit:conversion:to_new_layout
-- 
-- Use something like
-- mysql -u<mysql_user> <database_name> -p < lib/tasks/upload_nullable.sql
ALTER TABLE `staff_members` ADD COLUMN `upload_id` INT(10) UNSIGNED;
ALTER TABLE `repayment_styles` ADD COLUMN `upload_id` INT(10) UNSIGNED;
ALTER TABLE `loan_products` ADD COLUMN `upload_id` INT(10) UNSIGNED;
ALTER TABLE `funding_lines` ADD COLUMN `upload_id` INT(10) UNSIGNED;
ALTER TABLE `branches` ADD COLUMN `upload_id` INT(10) UNSIGNED;
ALTER TABLE `centers` ADD COLUMN `upload_id` INT(10) UNSIGNED;
ALTER TABLE `client_groups` ADD COLUMN `upload_id` INT(10) UNSIGNED;
ALTER TABLE `clients` ADD COLUMN `upload_id` INT(10) UNSIGNED;
ALTER TABLE `loans` ADD COLUMN `upload_id` INT(10) UNSIGNED;
