module Misfit
  module Config
    puts "Setting rights..."

    def self.model_names
      # Added an ugly patch for making alias of client_groups available
      DataMapper::Model.descendants.map{|d| d.to_s.snake_case.to_sym} << :group
    end

    def self.controller_names
      Application.subclasses_list.reject{|c| c.index("::")}.map{|x| x.snake_case.to_sym} + [:data_entry]
    end
      
    def self.all_models
      {:all => model_names}
    end

    def self.all_models_except(models)
      {:all => (model_names - models)}
    end

    def self.all_controllers
      {:all => controller_names}
    end

    def self.all_controllers_except(controllers)
      {:all => (controller_names - controllers)}
    end

    def controllers_from_models(role)
      @crud_rights[role]
    end

    @crud_rights = {
      :admin => all_models,
      :mis_manager => all_models_except([:user, :admin]),
      :data_entry => {
        :all => [:client, :loan, :payment, :document, :client_group, :group, :insurance_company, :insurance_policy],
      },
      :staff_member => {
        :all => [:center, :client, :loan, :payment, :document, :client_group, :group, :comment, :insurance_company, :staff_member]
      },
      :funder => {
        :all => []
      },
      :accountant => {
        :all => [:accounts, :journals, :rule_books, :account_types, :accounting_periods]
      }
    }

    @access_rights = {
      :admin => all_controllers,
      :mis_manager => all_controllers_except([:users, :admin]),
      :data_entry => {
        :all => [:search, :comments, :documents, :"data_entry/client_groups", :"data_entry/payments", :"data_entry/clients",:"data_entry/loans", :"data_entry/index", 
                :clients, :loans, :client_groups]
      },
      :read_only => {
        :all => [:searches, :browse, :branches, :centers, :payments, :clients, :loans, :dashboard, :regions, :reports, :documents, :comments, :insurance_policies, 
                 :insurance_companies, :areas, :staff_members, :loan_products, :holidays, :document_types, :occupations, :client_types, :fees, :funders, :attendances, :dashboard, :graph_data]
      },
      :staff_member => {
        :all => [:documents, :searches, :browse, :branches, :centers, :payments, :clients, :client_groups, :groups, :audit_trails, :comments, :insurance_policies, 
                 :reports, :"data_entry/centers", :"data_entry/client_groups", :"data_entry/payments", :"data_entry/clients", :staff_members, :audit_items,
                 :"data_entry/loans", :"data_entry/index", :insurance_companies, :info, :dashboard, :graph_data]
      },
      :funder => {
        :all => [:searches, :browse, :branches, :centers, :client_groups, :payments, :clients, :loans, :dashboard, :regions, :documents, :comments, :areas, 
                 :audit_trails, :documents, :attendances, :staff_members, :funders, :portfolios, :funding_lines, :reports, :graph_data, :dashboard]
      },
      :accountant => {
        :all => [:browse, :branches, :accounts, :journals, :rule_books, :account_types, :accounting_periods, :info, :reports]
      }
    }

    def self.crud_rights
      @crud_rights
    end

    def self.access_rights
      @access_rights
    end
    
    module DateFormat
      def self.compile
        if format = Mfi.first.date_format and not format.blank? and Mfi::DateFormats.include?(format)
          Date.class_eval do
            format = Mfi.first.date_format
            define_method :to_s do
              self.strftime(format)
            end
          end
        end
        
        Date.instance_eval do
          class << self 
            mfi = Mfi.first
            min_allowed_transaction_date = if mfi.min_date_from and mfi.number_of_past_days
                                             (mfi.min_date_from==:today ? Date.today : mfi.in_operation_since) - mfi.number_of_past_days
                                           elsif mfi.in_operation_since
                                             mfi.in_operation_since
                                           else              
                                             Date.new(2000, 01, 01)
                                           end
            
            min_allowed_date = if not mfi.in_operation_since.blank?
                                 mfi.in_operation_since 
                               else
                                 Date.new(2000, 01, 01)
                               end
            
            max_allowed_date = Date.today + mfi.number_of_future_days
            
            max_allowed_transaction_date =
              if mfi.number_of_future_days
                Date.today + mfi.number_of_future_transaction_days
              else              
                Date.today+1000
              end
            
            define_method :min_date do
              min_allowed_date
            end

            define_method :max_date do
              max_allowed_date
            end

            define_method :min_transaction_date do
              min_allowed_transaction_date
            end

            define_method :max_transaction_date do
              max_allowed_transaction_date
            end
          end
        end

        Merb.logger.info("Date format set to:: #{Mfi.first.date_format} and min date is #{Date.min_date}, max date is #{Date.max_date}, min transaction date is #{Date.min_transaction_date} and max transaction date is #{Date.max_transaction_date}")
      end
    end
  end
end
