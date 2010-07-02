# Go to http://wiki.merbivore.com/pages/init-rb

require 'config/dependencies.rb'

use_orm :datamapper
use_test :rspec
use_template_engine :haml

Merb::Dispatcher.use_mutex = false

Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:session_store] = 'cookie'  # can also be 'memory', 'memcache', 'container', 'datamapper

  # cookie session store configuration
  c[:session_secret_key]  = '573a2e64628a0656a8149f6f6b802d11bfc74123'  # required for cookie session store
  c[:session_id_key] = '_mostfit_session_id' # cookie session id key, defaults to "_session_id"
end

Merb::BootLoader.before_app_loads do
  DataMapper.setup(:abstract, "abstract::")
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
#  require 'csv'
  require 'uuid'
  require 'ftools'
  require 'logger'

  begin
    require 'dm-pagination'
    require 'dm-pagination/paginatable'
    require 'dm-pagination/pagination_builder'
    require "pdf/writer"
    require "pdf/simpletable"
    require 'lib/string.rb'
    require 'lib/grapher.rb'
    require("lib/pdfs/day_sheet.rb")
    require("lib/functions.rb")
    PDF_WRITER = true
  rescue
    PDF_WRITER = false
    puts "--------------------------------------------------------------------------------"
    puts "--------Do a gem install pdf-writer otherwise pdf generation won't work---------"
    puts "--------------------------------------------------------------------------------"
  end
  DataMapper::Model.append_extensions DmPagination::Paginatable
  if Merb.env=="development"
    Paperclip.options[:image_magick_path] = "/usr/bin"
    Paperclip.options[:command_path] = "/usr/bin"
  else
    Paperclip.options[:image_magick_path] = "/usr/bin"
    Paperclip.options[:command_path] = "/usr/bin"
  end
  # load the extensions
  require 'lib/extensions.rb'
end

Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
  # Load MFI account details to allow this app to sync phone numbers of staffmembers to mostfit box. If this file is not present then no such updates will happen
  loan_types = Loan.descendants

  begin; $holidays = Holiday.all.map{|h| [h.date, h]}.to_hash; rescue; end
  # Starting the logger takes time, so turn it off during development
#  Misfit::Logger.start(['Loans', 'Clients','Centers','Branches','Payments', 'DataEntry::Payments']) #unless Merb.environment == "development" or Merb.environment == "test"
  # Load the validation hooks
  # ruby is too beautiful. 3 lines of code and all payments can get their appropriate validations which are decided by the
  # loan product.
  Misfit::PaymentValidators.instance_methods.map{|m| m.to_sym}.each do |s|
    clause = Proc.new{|t| t.loan and (t.loan.loan_product.payment_validations.include?(s))}
    if DataMapper::VERSION == "0.10.1"
      Payment.add_validator_to_context({:context =>  :default, :if => clause}, [s], DataMapper::Validate::MethodValidator)
    elsif DataMapper::VERSION == "0.10.2"
      Payment.send(:add_validator_to_context, {:context => [:default], :if => clause}, [s], DataMapper::Validate::MethodValidator)
    end
  end
  Misfit::LoanValidators.instance_methods.map{|m| m.to_sym}.each do |s|
    clause = Proc.new{|t| t.loan_product.loan_validations.include?(s)}
    Loan.descendants.each do |loan|
      if DataMapper::VERSION == "0.10.1"
        loan.add_validator_to_context({:context =>  :default, :if => clause}, [s], DataMapper::Validate::MethodValidator)
      elsif DataMapper::VERSION == "0.10.2"
        loan.send(:add_validator_to_context,{:context => [:default], :if => clause}, [s], DataMapper::Validate::MethodValidator)
      end
    end
  end

  # set the rights
  require 'config/misfit'

  # enable the extensions
  Misfit::Extensions.hook

  Merb.add_mime_type(:pdf, :to_pdf, %w[application/pdf], "Content-Encoding" => "gzip")
  LoanProduct.property(:loan_type, LoanProduct::Enum.send('[]', *Loan.descendants.map{|x| x.to_s}), :nullable => false, :index => true)
  begin
    if User.all.empty?
      u = User.new(:login => 'admin', :password => 'password', :password_confirmation => 'password', :role => :admin)
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

  begin 
    if Currency.all.empty?
      curr = Currency.new(:name => 'INR')
      if curr.save
        Merb.logger.info("The initial Currency 'INR' was created...")
      else
        Merb.logger.info("Conldn't create the 'INR' currency.......")
        u.errors.each do |e|
          Merb.logger.info(e)
        end
      end
    end
    
  rescue
    Merb.logger.info("Couldn't create the 'INR' currency, Possibly unable to access the database.")
  end
  
  VOUCHERS = ['Payment', 'Receipt', 'Journal']
  
  begin 
    if JournalType.all.empty?
      VOUCHERS.each do |x|
        j = JournalType.new(:name => x )
        if j.save
          Merb.logger.info("The initial Voucher was created...")
        else
          Merb.logger.info("Conldn't create the Voucher.......")
          u.errors.each do |e|
            Merb.logger.info(e)
          end
        end
      end
    end
  rescue
    Merb.logger.info("Couldn't create the voucher, Possibly unable to access the database.")
  end
  
#  Mime::Type.register 'application/pdf', :pdf
  if File.exists?(File.join(Merb.root, "config", "mfi.yml"))
    $globals ||= {}
    begin
      $globals[:mfi_details] = YAML.load(File.read(File.join(Merb.root, "config", "mfi.yml")))
    rescue
      Merb.logger.info("Couldn't not load MFI details from config/mfi.yml. Possibly a wrong YAML file specification.")
    end
  end
  Misfit::Config::DateFormat.compile

  module DmPagination
    class PaginationBuilder
      def url(params)
        @context.params.delete(:action) if @context.params[:action] == 'index'
        @context.url(@context.params.merge(params).reject{|k,v| k=="_message"})
      end
    end
  end


end

