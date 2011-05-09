desc 'Create a pair of duplicate clients.'
namespace :mostfit do
  task :create_duplicate_clients do
    
    common_properties = {
      :name           => "Foo Bar",
      :spouse_name    => "Moo Bar",
      :date_of_birth  => Date.parse('1991-06-08'),
      :date_joined    => Date.today,
      :client_type_id => 1,

      # pick associations from the existing data
      :center                     => Center.first,
      :created_by_user_id         => User.first.id,
      :created_by_staff_member_id => StaffMember.first.id
    }

    # mostfit already depends on UUID gem; use it to generate unique references
    c1 = Client.create(common_properties.merge({:reference => UUID.generate}))
    c2 = Client.create(common_properties.merge({:reference => UUID.generate}))

    if c1.save and c2.save
      puts "Created a pair of duplicate clients."
    else
      c1.errors.each {|e| puts e}
      c2.errors.each {|e| puts e}
    end
  end
end
