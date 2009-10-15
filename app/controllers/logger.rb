module Misfit
  module Logger
    
    def self.start(controllers)
      controllers.each do |c|
        controller = Kernel.const_get(c)
        controller.add_filter(controller._before_filters, :get_object_state, {:only => ['update']})
        controller.add_filter(controller._after_filters, :_log, {:only => ['update','create']})
      end
    end
  end
end



