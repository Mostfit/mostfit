# Go to http://wiki.merbivore.com/pages/init-rb
 
require 'config/dependencies.rb'

use_orm :datamapper
use_test :rspec
use_template_engine :haml
 
Merb::Config.use do |c|
  c[:use_mutex] = true
  c[:session_store] = 'cookie'  # can also be 'memory', 'memcache', 'container', 'datamapper
  
  # cookie session store configuration
  c[:session_secret_key]  = '573a2e64628a0656a8149f6f6b802d11bfc74123'  # required for cookie session store
  c[:session_id_key] = '_mostfit_session_id' # cookie session id key, defaults to "_session_id"
end
 
Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
  Extlib::Inflection.word('loan_history')  # i dont like a table named 'loan_histories'
  Extlib::Inflection.word('audit_trail')   # i dont like a table named 'audit_trails'
  Extlib::Inflection.word('attendancy')    # i dont like a table named 'attendancies'
  Numeric::Transformer.add_format(
    :mostfit_default => { :number =>   { :precision => 3, :delimiter => ' ',  :separator => '.'},
                          :currency => { :unit => '',     :format => '%n',    :precision => 0 } },
    :in              => { :number =>   { :precision => 3, :delimiter => ',',  :separator => '.'},
                          :currency => { :unit => 'Rs.',  :format => '%u %n', :precision => 0 } })
  Numeric::Transformer.change_default_format(:mostfit_default)
  require 'config/constants.rb'
  require 'csv'
  require 'uuid'
  require 'ftools'
  require 'logger'

  begin
    require "pdf/writer"
    require "pdf/simpletable"
    require "lib/logger.rb"
    require 'lib/string.rb'
    require("lib/pdfs/day_sheet.rb")
    require("lib/functions.rb")
    PDF_WRITER = true
  rescue
    PDF_WRITER = false
    puts "--------------------------------------------------------------------------------"
    puts "--------Do a gem install pdf-writer otherwise pdf generation won't work---------"
    puts "--------------------------------------------------------------------------------"
  end
  Paperclip.options[:image_magick_path] = "/usr/local/bin"
  Paperclip.options[:command_path] = "/usr/local/bin"
end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
  # Load MFI account details to allow this app to sync phone numbers of staffmembers to mostfit box. If this file is not present then no such updates will happen
  MFI_DETAILS = YAML.load(File.read(File.join(Merb.root, "config", "mfi.yml")))
  # Starting the logger takes time, so turn it off during development
  Misfit::Logger.start(['Loans', 'Clients','Centers','Branches','Payments']) unless Merb.environment == "development" or Merb.environment == "test"

  Merb.add_mime_type(:pdf, :to_pdf, %w[application/pdf], "Content-Encoding" => "gzip")
  LoanProduct.property(:loan_type, LoanProduct::Enum.send('[]', *Loan.descendants.map{|x| x.to_s}), :nullable => false, :index => true)
  begin
    if User.all.empty?
      u = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password', :admin => true)
      if u.save
        Merb.logger.info("The initial user 'admin' was created (password is set to 'password')...")
      else
        Merb.logger.info("Couldn't create the 'admin' user...")
        u.errors.each do |e|
          Merb.logger.info(e)
        end
      end
    end
  rescue
    Merb.logger.info("Couldn't create the 'admin' user, possibly unable to access the database.")
  end
#  Mime::Type.register 'application/pdf', :pdf
end

