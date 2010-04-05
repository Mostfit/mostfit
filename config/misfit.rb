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
        :all => [:client, :loan, :payment, :document, :client_groups, :groups],
      },
      :staff_member => {
        :all => [:client, :loan, :payment, :documents, :client_groups, :groups]
      }
    }

    @access_rights = {
      :admin => all_controllers,
      :mis_manager => all_controllers_except([:users, :admin]),
      :data_entry => {
        :all => [:search, :documents, :"data_entry/payments",:"data_entry/clients",:"data_entry/loans", :"data_entry/index"]
      },
      :read_only => {
        :all => [:search, :browse, :branches, :centers, :payments, :clients, :loans, :dashboard, :regions, :reports, :documents]
      },
      :staff_member => {
        :all =>[:documents, :search, :browse, :centers, :payments, :clients, :client_groups, :groups, :audit_trail,
                :reports, :"data_entry/payments", :"data_entry/clients", :"data_entry/loans", :"data_entry/index"]
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
        if $globals and $globals[:mfi_details] and format=$globals[:mfi_details][:date_format] and Mfi::DateFormats.include?(format)
          Date.class_eval do
            def to_s
              self.strftime($globals[:mfi_details][:date_format])
            end
          end
          Date.instance_eval do
            def min_date
              if $globals && $globals[:mfi_details] && $globals[:mfi_details][:in_operation_since] and not $globals[:mfi_details][:in_operation_since].blank?
                $globals[:mfi_details][:in_operation_since]
              else
                Date.parse("2000-01-01")
              end
            end
          end
          Date.instance_eval do
            def max_date
              today+1000
            end
          end
          Merb.logger.info("Date format set to:: #{$globals[:mfi_details][:date_format]} and min date is #{Date.min_date}")
        end
      end
    end
  end
end
