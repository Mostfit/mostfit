require "rubygems"

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
  namespace :data do
    desc "This rake task anonymizes client data"
    task :anonymize do
      #Add any model that may have sensitive data that should be wiped for anonymising, to the array below
      models_to_anonymise = [ Region, Area, Branch, Center, ClientGroup, Client, Guarantor,LoanProduct, StaffMember, InsurancePolicy, Funder, Account, BranchDiary, Document ]

      #Add any model where all rows may be just deleted to the array below
      models_to_nuke = [ AuditTrail, Report ] 
      
      #Add any 'property' on models that needs to be wiped
      #!!!REMEMBER!!! the update sql generated currently handles only strings as it quotes the new values
      fields_to_wipe_strings = [ :name, :address, :contact_number, :landmark, :reference, :spouse_name, :mobile_number, :father_name, :nominee, :beneficiary_name, :branch_name, :center_leader_name, :place_of_birth, :issuing_authority, :number ]
     
      #We don't always follow the convention for the table name derived from the name of the model, add the exceptions here
      inflections = { AuditTrail => 'audit_trail', InsurancePolicy => 'insurance_policies' }
      
      #For certain fields, you can suggest the value that will be used as the 'stem' when updated
      fields_to_wipe_strings_suggestions = { :spouse_name => "bindni", :mobile_number => "98123" }

      models_to_nuke.each do |model|
        table = inflections[model] || model.to_s.snake_case.pluralize
        nuke_sql = "delete from #{table}"
        repository.adapter.execute(nuke_sql)
      end

      models_to_anonymise.each do |model|
        table = inflections[model] || model.to_s.snake_case.pluralize
        model_string = model.to_s          
        new_values = []
        instance = model.new
        fields_to_wipe_strings.each do |field|
          if (instance.respond_to?(field))
            col_name = field.to_s; 
            col_value_stem = fields_to_wipe_strings_suggestions[field] || "#{field}"
            new_values.push([col_name, col_value_stem])
          end
        end
        model_ids = repository.adapter.query("select id from #{table}")
        model_ids.each do |row_id|
          update_sql = "update #{table} set "
          is_first_value = true
          new_values.each do |column_and_value|
            if is_first_value
              is_first_value = false
            else
              update_sql += ", "
            end
            update_sql += "#{column_and_value.first} = '#{column_and_value.last} #{row_id}'"
          end
          update_sql += " where id = #{row_id}" 
          #CAVEAT: column width may be exceeded unpredictably on certain fields and models, 
          #in which case, try adding a suggestion to fields_to_wipe_strings_suggestions and run again
          repository.adapter.execute(update_sql)     
        end
      end
    end
  end
end
