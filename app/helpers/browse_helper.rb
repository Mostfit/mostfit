module Merb
  module BrowseHelper
    @@charts = []

    def random_chart
      begin
        seg = ""
        find_all_charts if @@charts.length==0
        params ={}      
        eval(@@charts[(rand()*@@charts.length).to_i])
      rescue
      end
    end
    
    def find_all_charts
      return unless File.exists?(File.join(Merb.root, "app", "views", "dashboard", "index.html.haml"))
      @@charts = File.read(File.join(Merb.root, "app", "views", "dashboard", "index.html.haml")).find_all{|x|
        x.include?("chart")
      }.map{|x|
        x.strip.gsub(/^=/, "")
      }.map{|x| 
        if x.include?("url(") and not x.include?("dashboard") and not x.include?(":controller")
          x.gsub("url(", "url(:controller => 'dashboard',").gsub(/(\d+\,\s?\d+)/, '400, 270')
        else
          x.gsub(/(\d+\,)/, '400,')
        end
      }
    end
  end
end # Merb
