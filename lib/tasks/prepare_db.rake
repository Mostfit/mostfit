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
         alter table loan_history modify actual_outstanding_total   decimal(15,2) not null, 
                             modify scheduled_outstanding_total     decimal(15,2) not null,
                             modify actual_outstanding_principal    decimal(15,2) not null,
                             modify scheduled_outstanding_principal decimal(15,2) not null,
                             modify scheduled_principal_due         decimal(15,2) not null,
                             modify scheduled_interest_due          decimal(15,2) not null,
                             modify principal_due                   decimal(15,2) not null,
                             modify interest_due                    decimal(15,2) not null,
                             modify principal_paid                  decimal(15,2) not null,
                             modify interest_paid                   decimal(15,2) not null,
                             modify total_interest_due              decimal(15,2) not null,
                             modify total_principal_due             decimal(15,2) not null,
                             modify total_principal_paid            decimal(15,2) not null,
                             modify total_interest_paid             decimal(15,2) not null,
                             modify advance_principal_paid          decimal(15,2) not null,
                             modify advance_interest_paid           decimal(15,2) not null,
                             modify advance_principal_paid_today    decimal(15,2) not null,
                             modify advance_interest_paid_today     decimal(15,2) not null,
                             modify total_advance_paid              decimal(15,2) not null,
                             modify total_advance_paid_today        decimal(15,2) not null,
                             modify advance_principal_adjusted      decimal(15,2) not null,
                             modify advance_interest_adjusted       decimal(15,2) not null,
                             modify principal_in_default            decimal(15,2) not null,
                             modify interest_in_default             decimal(15,2) not null,
                             modify total_fees_due                  decimal(15,2) not null,
                             modify total_fees_paid                 decimal(15,2) not null,
                             modify fees_due_today                  decimal(15,2) not null,
                             modify composite_key                   decimal(10,4) not null default 0,
                             modify applied                         decimal(15,2) not null default 0,
                             modify applied_count                   integer not null default 0,
                             modify approved                        decimal(15,2) not null default 0,
                             modify approved_count                  integer not null default 0,
                             modify rejected                        decimal(15,2) not null default 0,
                             modify rejected_count                  integer not null default 0,
                             modify disbursed                       decimal(15,2) not null default 0,
                             modify disbursed_count                 integer not null default 0,
                             modify outstanding                     decimal(15,2) not null default 0,
                             modify outstanding_count               integer not null default 0,
                             modify repaid                          decimal(15,2) not null default 0,
                             modify repaid_count                    integer not null default 0,
                             modify written_off                     decimal(15,2) not null default 0,
                             modify written_off_count               integer not null default 0,
                             modify claim_settlement                decimal(15,2) not null default 0,
                             modify claim_settlement_count          integer not null default 0,
                             modify preclosed                       decimal(15,2) not null default 0,
                             modify preclosed_count                 integer not null default 0;
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
                             modify applied                     decimal(15,2) not null,
                             modify applied_count               integer not null,
                             modify approved                    decimal(15,2) not null,
                             modify approved_count              integer not null,
                             modify rejected                    decimal(15,2) not null,
                             modify rejected_count              integer not null,
                             modify disbursed                   decimal(15,2) not null,
                             modify disbursed_count             integer not null,
                             modify outstanding                 decimal(15,2) not null,
                             modify outstanding_count           integer not null,
                             modify repaid                      decimal(15,2) not null,
                             modify repaid_count                integer not null,
                             modify written_off                 decimal(15,2) not null,
                             modify written_off_count           integer not null,
                             modify claim_settlement            decimal(15,2) not null,
                             modify claim_settlement_count      integer not null,
                             modify preclosed                   decimal(15,2) not null,
                             modify preclosed_count             integer not null;
         })
    end

    # the following three tasks make it easy to create a massive database from a small one.
    # simply create a dummy database
    # then
    # rake mostfit:db:copy_tables[dummy]      - copies the relevant tables to the dummy database
    # rake mostfit:db:up_ids[dummy]           - bumps ids on the tables in the dummy database
    # rake mostfit:db:copy_tables_back[dummy] - merges the tables from the dummy database into your database.

    # by this point, the database should have doubled in size.
    # repeat!

    desc "copies financial tables to a new database"
    task :copy_tables, :database do |task, args|
      db = args[:database]
      tables = %w{branches centers clients loans payments loan_history funders funding_lines users staff_members areas regions comments client_groups occupations applicable_fees repayment_styles loan_products insurance_policies fees}
      tables.each do |t|
        puts "dropping table #{db}.#{t}"
        repository.adapter.execute("drop table if exists #{db}.#{t}")
        puts "copying #{t} to #{db}.#{t}"
        repository.adapter.execute("create table #{db}.#{t} select * from #{t}")
      end
    end

    desc "increases ids by max(id) to easily copy back into legacy database"
    task :up_ids, :database do |task, args|
      db = args[:database]
      max = {:branches => nil, :centers => nil, :clients => nil, :loans => nil, :payments => nil, :client_groups => nil}
      # get the max id for each table
      max.keys.each {|k| max[k] = repository.adapter.query("select max(id) from #{db}.#{k.to_s}")[0]}
      max.each{|k,v| puts "#{k}:#{v}"}

      # update the ids
      max.keys.each {|k| 
        puts "up-ing ids for #{db}.#{k.to_s}"
        repository.adapter.execute("update #{db}.#{k.to_s} set id = id + #{max[k]}")
      }
      
      #update the children
      update = {:centers => [:branch], :clients => [:center, :client_group], :client_groups => [:center],
        :loans => [:client], :attendances => [:client, :center], :payments => [:loan, :client, :c_branch, :c_center], 
        :insurance_policies => [:loan, :client], :loan_history => [:loan, :client, :center, :branch]}
      update.each do |k,v|
        v.each do |f|
          max_key = f.to_s.match(/^c_/) ? f.to_s.split("_")[1].pluralize.to_sym : f.to_s.pluralize.to_sym
          puts "\t updating children for #{db}.#{k.to_s}"
          repository.adapter.execute("update #{db}.#{k.to_s} set #{f.to_s}_id = #{f.to_s}_id + #{max[max_key]}")
        end
      end
    end

    desc "copies the updated tables back into the original database"
    task :copy_tables_back, :database do |task, args|
      db = args[:database]
      tables = %w{branches centers clients loans payments loan_history}
      tables.each do |t|
        puts "copying #{db}.#{t} to #{t}"
        repository.adapter.execute("insert into #{t} select * from #{db}.#{t}")
      end
    end

    desc "does all three tasks above"
    task :fatten_db, :database do |task, args|
      db_name = args[:database]
      #mostfit:db:copy_tables').invoke(db_name)
      #Rake::Task('mostfit:db:up_ids').invoke(db_name)
      #Rake::Task('mostfit:db:').invoke(db_name)
    end


  end
end
    


