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
    yml_file =  "spec/fixtures/#{name}.yml"
    puts "\nLoading: #{yml_file}"
    entries = YAML::load_file(Merb.root / yml_file)
    entries.each do |name, entry|
      k = klass::new(entry)
      unless k.save
        puts "Validation errors saving a #{klass}:"
        p k.errors
      end
    end
  end
end



namespace :mock do
  desc "Generate some 'clever-random' payments"
  task :payments do
    puts "Not implemented yet..."
  end


  desc "Make history (from first approved loan till today)"
  task :history do
    puts "Obsoleted by giving Loan the responsibility to do it by itself, just mock:fixtures will do..."
#     date = Loan.first(:order => [:approved_on]).approved_on
#     t0, days = Time.now, (Date.today - date)
#     Merb.logger.info! "Start mock:history rake task from #{date}, for #{days} days, at #{t0}"
#     while date <= Date.today
#       LoanHistory.run(date)
#       date += 1
#     end
#     t1 = Time.now
#     secs = (t1 - t0).round
#     Merb.logger.info! "Finished mock:history rake task in #{secs} secs for #{days} days (#{format("%.3f", secs.to_f/days)} secs/day), at #{t1}"
  end

  desc "Drop current db and load fixtures from /spec/fixtures (and work the update_history jobs down)"
  task :fixtures do
    DataMapper.auto_migrate! if Merb.orm == :datamapper

    # loading is ordered, important for our references to work
    load_fixtures :users, :staff_members, :branches, :centers, :clients, :loans  #, :payments

    t0 = Time.now
    puts "Starting workers on the queue of history_update jobs at #{t0}"
    5.times { Merb::Worker.new }  # put a few workers on the queue
    while (queue_size = Merb::Dispatcher.work_queue.size) > 0
      puts "Still #{queue_size} jobs in the work queue...\n"
      sleep(5)
    end
    t1 = Time.now
    sleep(6)  # allow some last, dangling task to finish
    Merb.logger.flush
    puts
    puts "Finished the queue of history_update jobs in #{(t1 - t0).round} secs, at #{t1}"
    puts
    puts "Fixtures have been loaded."
  end
end





# some fixture loader if found online, more features, none we need so far it seems...
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