if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')
require File.join(Merb.root, "lib", "form_compiler")

namespace :mostfit do
  namespace :form do
    desc "Compile form for given model"
    task :compile, :model do |task, args|
      if args[:model]
        model = args[:model]
        original_file =  File.readlines(File.join(Merb.root, "app/views/#{model}/_fields.html.haml"))

        if not original_file[0].strip=="%div.tab_container"
          File.move(File.join(Merb.root, "app/views/#{model}/_fields.html.haml"), File.join(Merb.root, "app/views/#{model}/_basic_info.html.haml"))
        end

        f = File.open(File.join(Merb.root, "app/views/#{model}/_fields.html.haml"), "w")
        f.puts "%div.tab_container"
        f.puts "  %ul.tabs"
        
        tabs = [["basic_info", "Basic info"]]
      	Dir.new(File.join(Merb.root, "config/forms/#{model}")).entries.find_all{|x| /\.yml$/.match(x)}.sort.each{|file|
          form  = CustomForm::Compiler.new(model, file)          
          form.compile
          tabs.push([form.form_name, form.form_name.camelcase(' ')])
        }
        tabs.each{|x|
          f.puts "    %li##{x[0]} #{x[1]}"
        }
        tabs.each{|x|
          f.puts "  %div.tab"
          f.puts "    =partial '#{model}/#{x[0]}'"
        }
        f.close
      else
        "no filename given"
      end
    end
  end
end
