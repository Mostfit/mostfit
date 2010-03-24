module Misfit
  module Logger
    def self.start(controllers)
      controllers.each do |c|
        if c.index("::")  
          k = Kernel.const_get(c.split("::")[0])
          c = c.split("::")[1]
        else 
          k = Kernel
        end
        cont = k.const_get(c)
        cont.class_eval do
          include Misfit::ControllerFunctions
        end
        cont.add_filter(cont._before_filters, :get_object_state, {:only => ['update']})
        cont.add_filter(cont._after_filters, :_log, {:only => ['update','create']})
      end
    end
  end
end

    
module Misfit
  module ControllerFunctions

    def self.included(base)
      Merb.logger.info("#{base.to_s} included Controllerfunctions")
    end

    def self.extended(base)
      base.extend ClassMethods
      Merb.logger.info("#{base.to_s} extended Controllerfunctions")
    end      


    def get_object_state
      model = self.class.to_s.singular
      object = eval "#{model}.get(params[:id])"
      @ributes = object.attributes
    end
    
    def _log
      f = File.open("log/#{self.class}.log","a")
      begin
        object = eval("@#{self.class.to_s.downcase.singular}")
        if object
          attributes = object.attributes
          if @ributes
            diff = @ributes.diff(attributes)
            diff = diff.map{|k| {k => [@ributes[k],attributes[k]]} if k != :updated_at}.to_yaml
          else
            diff = attributes.map{|k, v| {k => [attributes[k]]} if k != :updated_at}.to_yaml
          end
          log = AuditTrail.new(:auditable_id => object.id, :action => params[:action], :changes => diff, :type => :log,
                               :auditable_type => object.class.to_s, :user => session.user)  
          log.save
        end
      rescue Exception => e
        puts e
        puts e.backtrace
      end
    end
  end
end


