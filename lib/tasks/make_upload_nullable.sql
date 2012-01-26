-- 
-- the new app/models/upload.rb defines has n, model relationships on all of the following: 
--   MODELS = [:staff_members, :repayment_styles, :loan_products, :funding_lines, :branches, :centers, :client_groups, :clients, :loans]
-- please run the below script first WHEN you switch from :migration mode to :running mode
-- 
-- Use something like
-- mysql -u<mysql_user> <database_name> -p < lib/tasks/upload_nullable.sql
ALTER TABLE `staff_members` CHANGE COLUMN `upload_id` `upload_id` INT(10) UNSIGNED NULL;
ALTER TABLE `repayment_styles` CHANGE COLUMN `upload_id` `upload_id` INT(10) UNSIGNED NULL;
ALTER TABLE `loan_products` CHANGE COLUMN `upload_id` `upload_id` INT(10) UNSIGNED NULL;
ALTER TABLE `funding_lines` CHANGE COLUMN `upload_id` `upload_id` INT(10) UNSIGNED NULL;
ALTER TABLE `branches` CHANGE COLUMN `upload_id` `upload_id` INT(10) UNSIGNED NULL;
ALTER TABLE `centers` CHANGE COLUMN `upload_id` `upload_id` INT(10) UNSIGNED NULL;
ALTER TABLE `client_groups` CHANGE COLUMN `upload_id` `upload_id` INT(10) UNSIGNED NULL;
ALTER TABLE `clients` CHANGE COLUMN `upload_id` `upload_id` INT(10) UNSIGNED NULL;
ALTER TABLE `loans` CHANGE COLUMN `upload_id` `upload_id` INT(10) UNSIGNED NULL;
