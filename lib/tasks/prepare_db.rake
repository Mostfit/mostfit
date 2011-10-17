# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace :mostfit do
  namespace :db do
    desc "populate the database using the csv's"
    task :prepare do
      repository.adapter.execute(%Q{
         alter table loan_history modify actual_outstanding_total decimal(15,2) not null, 
                             modify scheduled_outstanding_total decimal(15,2) not null,
                             modify actual_outstanding_principal decimal(15,2) not null,
                             modify scheduled_outstanding_principal decimal(15,2) not null,
                             modify scheduled_principal_due decimal(15,2) not null,
                             modify scheduled_interest_due  decimal(15,2) not null,
                             modify principal_due  decimal(15,2) not null,
                             modify interest_due decimal(15,2) not null,
                             modify principal_paid  decimal(15,2) not null,
                             modify interest_paid  decimal(15,2) not null,
                             modify total_interest_due  decimal(15,2) not null,
                             modify total_principal_due  decimal(15,2) not null,
                             modify total_principal_paid  decimal(15,2) not null,
                             modify total_interest_paid  decimal(15,2) not null,
                             modify advance_principal_paid decimal(15,2) not null,
                             modify advance_interest_paid  decimal(15,2) not null,
                             modify advance_principal_adjusted  decimal(15,2) not null,
                             modify advance_interest_adjusted   decimal(15,2) not null,
                             modify principal_in_default        decimal(15,2) not null,
                             modify interest_in_default         decimal(15,2) not null,
                             modify total_fees_due               decimal(15,2) not null,
                             modify total_fees_paid            decimal(15,2) not null,
                             modify fees_due_today              decimal(15,2) not null,
                             modify composite_key              decimal(10,4) not null;
         })
      repository.adapter.execute(%Q{
         alter table cachers modify actual_outstanding_total decimal(15,2) not null, 
                             modify scheduled_outstanding_total decimal(15,2) not null,
                             modify actual_outstanding_principal decimal(15,2) not null,
                             modify scheduled_outstanding_principal decimal(15,2) not null,
                             modify scheduled_principal_due decimal(15,2) not null,
                             modify scheduled_interest_due  decimal(15,2) not null,
                             modify principal_due  decimal(15,2) not null,
                             modify interest_due decimal(15,2) not null,
                             modify principal_paid  decimal(15,2) not null,
                             modify interest_paid  decimal(15,2) not null,
                             modify total_interest_due  decimal(15,2) not null,
                             modify total_principal_due  decimal(15,2) not null,
                             modify total_principal_paid  decimal(15,2) not null,
                             modify total_interest_paid  decimal(15,2) not null,
                             modify advance_principal_paid decimal(15,2) not null,
                             modify advance_interest_paid  decimal(15,2) not null,
                             modify advance_principal_adjusted  decimal(15,2) not null,
                             modify advance_interest_adjusted   decimal(15,2) not null,
                             modify principal_in_default        decimal(15,2) not null,
                             modify interest_in_default         decimal(15,2) not null,
                             modify total_fees_due               decimal(15,2) not null,
                             modify total_fees_paid            decimal(15,2) not null,
                             modify fees_due_today              decimal(15,2) not null;
         })
    end


    desc "copies financial tables from new_layout"
    task :copy_tables, :database do |task, args|
      db = args[:database]
      tables = %w{branches centers clients loans payments loan_history funders funding_lines users staff_members areas regions comments client_groups occupations applicable_fees repayment_styles loan_products insurance_policies fees}
      tables.each do |t|
        repository.adapter.execute("drop table if exists #{t}")
        repository.adapter.execute("create table #{t} select * from #{db}.#{t}")
      end
    end

    desc "increases ids by max(id) to easily copy back into legacy database"
    task :up_ids do
      max = {:branches => nil, :centers => nil, :clients => nil, :loans => nil, :payments => nil, :client_groups => nil}
      # get the max id for each table
      max.keys.each {|k| max[k] = repository.adapter.query("select max(id) from #{k.to_s}")[0]}
      max.each{|k,v| puts "#{k}:#{v}"}

      # update the ids
      max.keys.each {|k| repository.adapter.execute("update #{k.to_s} set id = id + #{max[k]}")}
      
      #update the children
      update = {:centers => [:branch], :clients => [:center, :client_group], :client_groups => [:center],
        :loans => [:client], :attendances => [:client, :center], :payments => [:loan, :client, :c_branch, :c_center], 
        :insurance_policies => [:loan, :client], :loan_history => [:loan, :client, :center, :branch]}
      update.each do |k,v|
        v.each do |f|
          max_key = f.to_s.match(/^c_/) ? f.to_s.split("_")[1].pluralize.to_sym : f.to_s.pluralize.to_sym
          repository.adapter.execute("update #{k.to_s} set #{f.to_s}_id = #{f.to_s}_id + #{max[max_key]}")
        end
      end
    end

    desc "copies the updated tables back into the original database"
    task :copy_tables_back, :database do |task, args|
      db = args[:database]
      tables = %w{branches centers clients loans payments loan_history}
      tables.each do |t|
        repository.adapter.execute("insert into #{db}.#{t} select * from #{t}")
      end
    end

  end
end
    


