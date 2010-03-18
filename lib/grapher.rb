module Grapher
  COLOURS = ["edd400", "f57900", "c17d11", "73d216", "3465a4", "75507b", "cc0000"]
  class Graph
    attr_accessor :title, :type, :elements, :x_axis, :y_axis, :data_type
    def initialize(title, type)
      @elements = {:type => type, :values => []}
      @data_type = :cumulative
      unless type=="pie"
        @x_axis   = Axis.new("x")
        @y_axis   = Axis.new("y")
      end
      @title    = Title.new(title)
    end
    
    def values(val)
      @elements[:values].push(val)
    end

    def labels(val)
      @x_axis.labels.push(val.to_s)
    end

    def data(values_and_labels, value_method =:count, label_method=:date)
      count = 0
      values_and_labels.each{|row|
        if @data_type==:cumulative
          count+=row.send(value_method)
          values(count)
        else
          values(row.count)
        end
        labels(row.send(label_method))
      }
    end
    
    def generate
      @y_axis.smoothen(@elements[:values]) if @y_axis
      return {:elements => [@elements], :x_axis => (@x_axis ? @x_axis.generate : ""), :y_axis => (@y_axis ? @y_axis.generate : ""), :title => (@title ? @title.generate : "")}.to_json
    end
  end

  class Axis
    attr_accessor :rotation, :steps, :labels, :autoscale, :min, :max
    def initialize(type)
      @rotation = 0
      @steps    = 1
      @type     = type
      @labels   = []
      @autoscale = false
    end

    def smoothen(values)
      @min   = values.min > 0 ? 0 : values.min
      @max   = values.max > 0 ? values.max : 0
      @steps = get_steps(values.max)
    end

    def generate
      @rotation=270 if @rotation==0 and @labels.join.length/@steps>50
      if @type=="x"
        {:labels => {:steps => @steps, :rotate => @rotation, :labels => @labels}}
      else
        {:steps => @steps, :min => @min, :max => @max, :rotate => @rotation}
      end
    end

    private
    def get_steps(max)
      divisor = power(max)
      (max/(10**divisor)).to_i*10*divisor
    end
    
    def power(val, base=10)
      itr=1
      while val/(base**itr) > 1
        itr+=1
      end
      return itr-1
    end    
  end

  class Title
    attr_accessor :text
    def initialize(text)
      @text = text
    end
    
    def generate
      {:text => text}
    end
  end

  class BarGraph < Graph
    def initialize(title)
      super(title, "bar")
    end
  end

  class PieGraph < Graph
    def initialize(title)
      super(title, "pie")
    end

    def data(values_and_labels, value_method=:count, label_method=:date, colours=COLOURS)
      count = 0
      values_and_labels.each_with_index{|row, idx|
        self.values({:value => get_value(row, value_method), :label => row.send(label_method), :colour => colours[idx]})
      }
    end
    
    private
    def get_value(row, ms)
      if ms.class==Array
        ms.each{|m| 
          row=row.send(m)
        }
      else
        row=row.send(ms)
      end
      row
    end
  end
end
