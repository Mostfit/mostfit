module Grapher
  COLOURS = ["edd400", "f57900", "c17d11", "73d216", "3465a4", "75507b", "cc0000", "fce94f", "3465a4", "fcaf3e", "204a87", "ad7fa8", "a9a9a9", "9c5555", 
             "fa9ad7", "a57654", "76a554", "5476a5", "900f57", "21673d", "abcdef", "fcba45", "bafc87", "3efcf5", "a44567", "7fa8ad", "f02323", "b0a3f3",
             "abc123", "123abc", "5a6704", "293a47", "234def", "987def", "789056", "123456", "456789", "fefefe", "4512a9", "23f023", "ffffff"]
  class Graph
    attr_accessor :title, :type, :elements, :x_axis, :y_axis, :data_type
    def initialize(title, type)
      @elements = {:type => type, :values => []}
      @data_type = :cumulative
      @title    = Title.new(title)
    end
    
    def values(val)
      @elements[:values].push(val)
    end

    def get_values
      @elements[:values]
    end

    def data(values_and_labels, value_method =:count, label_method=:date)
      count = 0
      #set value and label methods to first and last if the set is an array
      if values_and_labels.first.class==Array and value_method==:count and label_method==:date
        value_method = :first
        label_method = :last
      end

      values_and_labels.each{|row|
        if @data_type==:cumulative
          count+=row.send(value_method)
          values(count)
        else
          values(row.send(value_method))
        end
        labels(row.send(label_method))
      }
    end
    
    def generate
      @y_axis.smoothen(@elements[:values]) if @y_axis and @elements[:values].length>0
      return {
        :elements => [@elements], :x_axis => (@x_axis ? @x_axis.generate : ""), :y_axis => (@y_axis ? @y_axis.generate : ""), 
        :title => (@title ? @title.generate : "")
      }.to_json
    end
  end

  class Axis
    attr_accessor :rotation, :steps, :labels, :autoscale, :min, :max
    def initialize(type)
      @rotation = 0
      @steps    = 1
      @type     = type
      @labels   = []
      @autoscale = true
    end

    def smoothen(values)
      @min   = values.min > 0 ? 0 : values.min
      @max   = values.max > 0 ? values.max : 0
      @steps = get_steps(values.max) if @autoscale
    end

    def generate
      @rotation=270 if @rotation==0 and @steps>0 and @labels.join.length/@steps>50
      if @type=="x"
        {:labels => {:steps => @steps, :rotate => @rotation, :labels => @labels}}
      else
        {:steps => @steps, :min => @min, :max => @max, :rotate => @rotation}
      end
    end

    private
    def get_steps(max)
      divisor = power(max)
      (max/(10**divisor))*(10**divisor)/10
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
    attr_accessor :x_axis, :y_axis
    def initialize(title)
      super(title, "bar")
      @x_axis   = Axis.new("x")
      @y_axis   = Axis.new("y")
    end

    def labels(val)
      @x_axis.labels.push(val.to_s)
    end
  end

  class PieGraph < Graph
    def initialize(title)
      super(title, "pie")
    end

    def data(values_and_labels, value_method=:count, label_method=:date, opts={})
      opts[:colour]= COLOURS if not opts[:colour]
      sum = 0      
      values_and_labels.each_with_index{|row, idx|        
        val = get_value(row, value_method)
        sum+= val
        self.values({:value => val, :label => row.send(label_method), :colour => opts[:colour][idx]})                      
      }
      self.get_values.each{|value|
        value[:tip] = "#{value[:label]}: #{(value[:value]*100.0/sum).round(2)}% (#{value[:value]})"
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
