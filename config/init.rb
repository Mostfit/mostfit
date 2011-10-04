# Go to http://wiki.merbivore.com/pages/init-rb
require 'lib/irb.rb'
require 'yaml'
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
  c[:session_id_key]      = '_mostfit_session_id' # cookie session id key, defaults to "_session_id"
  c[:session_expiry]      = 86400
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
    :in              => { :number =>   {:precision => 3, :delimiter => ',',  :separator => '.', :regex => /(\d+?)(?=(\d\d)+(\d)(?!\d))(\.\d+)?/},
                          :currency => { :format => '%u %n', :precision => 0, :delimiter => ',' } },
    :in_with_paise   => { :number =>   {:precision => 3, :delimiter => ',',  :separator => '.', :regex => /(\d+?)(?=(\d\d)+(\d)(?!\d))(\.\d+)?/},
                          :currency => { :format => '%u %n', :precision => 2, :delimiter => ',' } })
  Numeric::Transformer.change_default_format(:mostfit_default)
  require 'config/constants.rb'
  require 'lib/rules'
  require 'lib/reporting'
  require 'uuid'
  require 'ftools'
  require 'logger'
  require 'dm-pagination'
  require 'dm-pagination/paginatable'
  require 'dm-pagination/pagination_builder'
  require 'lib/string.rb'
  require 'lib/grapher.rb'
  require 'lib/functions.rb'
  require 'lib/core_ext.rb'
  require 'lib/fees_container.rb'
  require 'gettext'
  require 'haml_gettext'


  #initialize i18n
  require 'i18n'
  require 'i18n-translate'
  #load all localize file
  I18n::Backend::Simple.send(:include, I18n::Backend::Translate)
  I18n::Backend::Simple.send(:include, I18n::Backend::PO)
  I18n.load_path << "#{Merb.root}/config/locales/hi.po"
  I18n.load_path << "#{Merb.root}/config/locales/en.po"

  begin
    require "pdf/writer"
    require "pdf/simpletable"
    require("lib/pdfs/day_sheet.rb")
    require("lib/pdfs/loan_schedule.rb")
    PDF_WRITER = true
  rescue LoadError
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

  Merb::Plugins.config[:exceptions] = {
    :email_addresses => [''],
    :app_name        => "Mostfit",
    :environments    => ['production', 'development'],
    :email_from      => "",
    :mailer_config => {
      :host   => 'smtp.gmail.com',
      :port   => '587',
      :user   => '',
      :pass   => '',
      :auth   => :plain,
      :tls    => true
    },
    :mailer_delivery_method => :net_smtp
  }

end

Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
  # Activate SSL Support
  Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
 
  # Every application eventually evolves until it can send mail.
  # Configure Merb Mailer
  # Merb::Mailer.config = {
  #   :host   => 'smtp.gmail.com',
  #   :port   => '587',
  #   :user   => 'sidleypatang@gmail.com',
  #   :pass   => 's8s4a7m2',
  #   :auth   => :plain,
  #   :tls    => true
  # }

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
  require 'lib/reportage.rb'
  Mostfit::Business::Rules.deploy
  # enable the extensions
  Misfit::Extensions.hook

  Merb.add_mime_type(:pdf, :to_pdf, %w[application/pdf], "Content-Encoding" => "gzip")

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
    
  Mfi.activate

  if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      if forked
        DirtyLoan.start_thread
      end
    end
  end

  # This is to save all the loan_products as we have changed loan_type ENUM to loan_type_string.
  begin
    LoanProduct.all.each{ |l| 
      if l.loan_type.nil? or l.loan_type_string.nil?
        l.save
      end
    } 
  rescue
  end
  $holidays_list = []
  begin
    Holiday.all.each{|h| $holidays_list << [h.date.day, h.date.month, h.date.strftime('%y')]}
  rescue
  end

  #this is to create an Organization if it is not created.
  begin
    if Organization.all.empty?
      Organization.create(:name => "Mostfit", :org_guid => UUID.generate)
    end
  rescue
  end
end
