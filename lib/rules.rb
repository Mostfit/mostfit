module Mostfit
  module Business
    class BasicCondition
      attr_accessor :appliesOn, :operator, :compareWith, :validator
      
      def self.get_basic_condition(arr)
        if(arr.length != 3)
          return nil
        elsif((arr[0] == :and) || (arr[0] == :or) || (arr[0] == :not) )
          return nil
        else
          a = BasicCondition.new
          a.appliesOn = "DEFAULT" #wierd default to see if something fails
          a.operator = :ILLEGAL_OPERATOR
          a.compareWith = -1

          a.appliesOn = arr[0]
          if arr[1].class == Symbol
            arr[1] = arr[1].to_s #converts :less_than to "less_than"
          end
          a.operator = :<  if arr[1] == "less_than"
          a.operator = :<= if arr[1] == "less_than_equal"
          a.operator = :>  if arr[1] == "greater_than"
          a.operator = :>= if arr[1] == "greater_than_equal"
          a.operator = :== if (arr[1] == "equal1") or (arr[1] == "equal2") or (arr[1] == "equal")
          a.operator = "!=".to_sym if (arr[1] == "not1") or (arr[1] == "not2") or (arr[1] == "not")
          a.compareWith = arr[2]

          a.validator = Proc.new{|obj|
            if(a.appliesOn.respond_to?("split"))
              obj1 = a.appliesOn.split(".").map{|x| x.to_sym }.inject(obj){|s,x| 
                #puts "s:#{s}"
                #puts "x:#{x}"
                      if s != nil
                        s.send(x)
                      end
                      }
              if obj1 == nil
                true
              elsif a.operator == "!=".to_sym
                obj1 != a.compareWith
              else
                obj1.send(a.operator, a.compareWith)
              end
            else #appliesOn is a symbol
              obj1 = obj.send(a.appliesOn.to_s)
              if a.operator == :==
                obj1 == a.compareWith
              elsif a.operator == "!=".to_sym
                obj1 != a.compareWith
              else
                nil
              end
            end
          }
          return a
        end
      end

      def to_s
        return "#{@appliesOn} #{@operator} #{@compareWith}"
      end

      private_class_method :initialize #to prevent direct object creation
    end

    class ComplexCondition
      attr_accessor :is_basic_condition , :basic_condition #makes sense only if its a basic condition
      attr_accessor :operator #makes sense only if its not a basic condition
      attr_accessor :condition1, :condition2 #makes sense only if its not a basic condition

      def self.get_condition(arr)
        if(arr[0] == :not) then
          c = ComplexCondition.new
          c.operator = :not
          c.condition1 = ComplexCondition.get_condition(arr[1])
          c.condition2 = nil
          c.is_basic_condition = false
          return c
        elsif((arr[0] == :and) || (arr[0] == :or)) then
          c = ComplexCondition.new
          c.operator = arr[0]
          c.condition1 = ComplexCondition.get_condition(arr[1])
          c.condition2 = ComplexCondition.get_condition(arr[2])
          c.is_basic_condition = false
          return c
        else
          c = ComplexCondition.new
          c.is_basic_condition = true
          c.basic_condition = BasicCondition.get_basic_condition(arr)
          return c
        end
      end
      
      def check_condition(obj)
        if is_basic_condition
          return @basic_condition.validator.call(obj)
        elsif operator == :not
          return (not @condition1.check_condition(obj))
        elsif operator == :and
          return (@condition1.check_condition(obj) && @condition2.check_condition(obj))
        elsif operator == :or
          return (@condition1.check_condition(obj) || @condition2.check_condition(obj))
        end
      end

      def to_s
        if is_basic_condition
          basic_condition.to_s
        else
          "[#{@operator}: [#{@condition1}] [#{@condition2}]]"
        end
      end

      private :initialize
    end

    class Rules
      @@rules = {}
      REJECT_REGEX = /^(Merb|merb)::*/
      
      def self.deploy #apply the business rules
        #debugger
        begin 
          Rule.all.each do |r|
            r.apply_rule
          end
        rescue #TODO find a better way of handling situation when rules table is missing
          puts "Rules Engine not deployed. continuing"
        end
#        load(File.join(Merb.root, "config", "rules.rb"))
      end

      def initialize
      end
      
      def self.all_models #this is use to retrieve the list of all models
        #on which rules can be applied
        DataMapper::Model.descendants.reject{|x| x.superclass!=Object}.map{|d| d.to_s.snake_case.to_sym}
      end

      def self.tree
        DataMapper::Model.descendants.to_a.collect{|m| 
          {m => m.relationships}
        }.inject({}){|s,x| s+=x}.reject{|k,v| v.length==0}
      end
            
      def self.prepare(&blk) # blk contains a set of calls to allow() and
       # reject() to implement rules
        self.new.instance_eval(&blk)
      end

      def self.get_value_obj(obj, type)
        if type == "date"
          return Date.parse(obj)
        elsif type== "int"
          return obj.to_i
        elsif type== "float"
          return obj.to_f
        else
          return obj
        end
      end

			def self.apply_rule(rule)
        #debugger
		    condition1 = Array.new
				precondition1 = Array.new
				#generating polish notation in condition1
        if rule[:condition] != nil
  		    Marshal.restore(rule[:condition]).to_a.reverse!.each do |idx, cond|
  					if cond[:comparator] == nil or cond[:comparator].length ==0 or cond[:value] == nil or cond[:value].length == 0
  									return nil
  					end
  		      if cond[:linking_operator] != ""
  						condition1[2] = condition1.dup
  			  	  condition1[0] = cond[:linking_operator]
  						if condition1[0] == nil or condition1.length == 0
  										return nil
  						end
  			      condition1[1] = [ cond[:keys].join("."), cond[:comparator].to_s,
                      get_value_obj(cond[:value], cond[:valuetype])]
  					elsif
  						condition1 = [ cond[:keys].join("."), cond[:comparator].to_s,
                     get_value_obj(cond[:value], cond[:valuetype])]
  		      end
  		    end
        end
        if rule[:precondition] != nil
  		    Marshal.restore(rule[:precondition]).to_a.reverse!.each do |idx, cond|
  		      if cond[:linking_operator] != ""
  						precondition1[2] = precondition1.dup
  			  	  precondition1[0] = cond[:linking_operator]
  			      precondition1[1] = [ cond[:keys].join("."), cond[:comparator], cond[:value]]
  					elsif
  						precondition1 = [ cond[:keys].join("."), cond[:comparator], cond[:value]]
  		      end
  		    end
        end
		    h = {:name => rule[:name], :on_action => rule[:on_action], :model_name => rule[:model_name], 
			    :permit => rule[:permit], :condition => condition1, :precondition => precondition1}
				self.add h
			end

      #should not be called directly
      #only apply_rule should call this func
      def self.add(hash)
        if(hash[:model_name].class != Class)
          hash[:model_name] = Kernel.const_get(hash[:model_name].camelcase)
        end
        hash[:model_name].send(:define_method, hash[:name]) do
          puts "#{hash[:name]} called"
          if hash.key?(:permit)
            if(hash[:permit] == "false")
              hash[:condition] = [:not, [hash[:condition] ]]
            end
          end
          if hash.key?(:precondition) and hash[:precondition].length != 0 #result = not precondition OR (precondition AND condition)
            hash[:condition] = [:or, [:not, hash[:precondition]], 
              [:and, hash[:precondition], hash[:condition]] ]
          end
          c = ComplexCondition.get_condition(hash[:condition])
          #puts c.to_s
          if c.check_condition(self) then
            return true
          else
            puts "#{hash[:name]} violated"
            return [false, "#{hash[:name]} violated"]
          end
        end
        hash[:model_name].validates_with_method(hash[:name])
      end

      def self.remove_rule(hash)
        self.remove(hash)
      end

      #not to be called directly, call remove_rule instead
      #to remove a validation
      def self.remove(hash)
        if(hash[:model_name].class != Class)
          hash[:model_name] = Kernel.const_get(hash[:model_name].camelcase)
        end
        if hash[:model_name].new.respond_to?(hash[:name])
          hash[:model_name].send(:define_method, hash[:name]) do
            return true #overwrite the old function
          end
        end
        return true
      end

      def self.rules
        @@rules
      end

      private
      def get_condition(condition)
        if condition.class==Array
          condition[1] = :<  if hash[:condition][1] == :less_than
          condition[1] = :<= if hash[:condition][1] == :less_than_equal
          condition[1] = :>  if hash[:condition][1] == :greater_than
          condition[1] = :>= if hash[:condition][1] == :greater_than_equal
          condition[1] = :== if hash[:condition][1] == :equal
          validator = Proc.new{|obj|
            condition[0].split(".").map{|x| 
              x.to_sym
            }.inject(obj){|s,x| 
              s.send(x)
            }.send(condition[1], condition[2])
          }
        end
        validator
      end
    end
  end    
end    

