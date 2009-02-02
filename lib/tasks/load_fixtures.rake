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


def load_fixtures(*files)
  files.each do |name|
    klass = Kernel::const_get(name.to_s.singularize.camel_case)
    entries = YAML::load_file(Merb.root / "spec/fixtures/#{name}.yml")
    entries.each do |name, entry|
      k = klass::new(entry)
      unless k.save
        puts "Validation errors saving a #{klass}:"
        p k.errors
      end
    end
  end
end

namespace :db do
  desc "Load fixtures from /spec/fixtures"
  task :load_fixtures do
    DataMapper.auto_migrate! if Merb.orm == :datamapper

    # loading is ordered, important for our references to work
    load_fixtures :users, :staff_members, :branches, :centers, :clients, :loans  #, :payments

    puts "Fixtures have been loaded..."
  end
end






# # $map = Hash.new
# # 
# # path = Merb.root / "spec" / "fixtures"
# # files = ["users", "news_items", "privs"]
# # files.reverse.each { |f| f.classify.constantize.create_table! }
# # files.map! { |f| (path / f) + ".yml" }
# # 
# # files.each do |path|
# #   puts "Processing #{path}"
# #   fixtures = YAML::load_file(path) || {}
# #   klass = File.basename(path, ".yml")
# #   klass = klass.classify.constantize
# #   fixtures.each do |name, attributes|
# #     attributes.each_pair do |key, value|
# #       if value =~ /^@/
# #         methods = value[1 .. -1].split(".")
# #         m = methods.shift
# #         value = $map[m]
# #         raise "Value is nil for key '#{m}'" if value.nil?
# #         value = value.send(methods.shift) while !methods.empty?
# #         attributes[key] = value
# #       end
# #     end
# #     object = klass.new(attributes)
# #     raise "Object invalid: #{object.inspect}\n#{object.errors.inspect}" unless object.valid?
# #     object.save
# #     raise "Key '#{name}' already exists!" if $map[name]
# #     $map[name] = object
# #   end
# # end