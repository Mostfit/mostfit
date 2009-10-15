class Merb::Controller
  
  def start_logging(controllers)
    controllers.each do |c|
      controller = Kernel.const_get(c)
      controller.add_filter(controller._before_filters, :log)
    end
  end
  
  def log
    puts "logging"
  end
end

    
