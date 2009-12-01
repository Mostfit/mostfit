if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')
require File.join(Merb.root, "lib", "form_compiler")

namespace :form do
  desc "Compile form for given model"
  task :compile, :filename do |task, args|
    if args[:filename]
      filename = args[:filename]
      form  = CustomForm::Compiler.new(filename)
      form.compile
    else
      "no filename given"
    end
  end
end
