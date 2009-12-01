module Misfit
  module Config
    puts "Setting rights..."

    def self.model_names
      DataMapper::Model.descendants.map{|d| d.to_s.snake_case.to_sym}
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
        :all => [:client, :loan, :payment],
      },
      :staff_member => {
        :all => [:client, :loan, :payment]
      }
    }

    @access_rights = {
      :admin => all_controllers,
      :mis_manager => all_controllers_except([:users, :admin]),
      :data_entry => {
        :all => [:"data_entry/payments",:"data_entry/clients",:"data_entry/loans", :"data_entry/index"]
      },
      :staff_member => {
        :all =>[:browse, :centers, :payments, :clients, :"data_entry/payments", :"data_entry/clients", :"data_entry/loans", :"data_entry/index"],
      }
    }

    def self.crud_rights
      @crud_rights
    end

    def self.access_rights
      @access_rights
    end
  end
end
