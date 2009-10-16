module Misfit
  module Logger
    def self.start(controllers)
      debugger
      controllers.each do |c|
        puts "logging #{c}\n"
        cont = Kernel.const_get(c)
        cont.extend(Misfit::ControllerFunctions)
        cont.add_filter(cont._before_filters, :abc, {:only => ['update']})
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

    module ClassMethods

      def self.abc
        "def"
      end

      def get_object_state
        debugger
        model = self.class.to_s.singular
        object = eval"#{model}.get(params[:id])"
        @ributes = object.attributes
      end
      
      def _log
        debugger
        f = File.open("log/#{self.class}.log","a")
        object = eval("@#{self.class.to_s.downcase.singular}")
        if object
          attributes = object.attributes
          diff = @ributes.diff(attributes)
          diff_string = diff.map{|k| "#{k} from #{@ributes[k]} to #{attributes[k]}" if k != :updated_at}.join("\t")
          log = "#{Time.now}\t#{session.user.login}\t#{diff_string}\n"
          f.write(log)
          f.close
          Merb.logger.info(log)
        end
      end
    end
  end
end
