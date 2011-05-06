module Mostfit
  module Business
    class BasicCondition
      #      attr_accessor :appliesOn, :operator, :compareWith, :validator
      attr_accessor :var1, :binaryoperator, :var2, :comparator, :const_value, :validator
      
      def self.get_basic_condition(cond)
        if(cond.keys.length < 3)
          return nil
        else
          a = BasicCondition.new
          a.var1 = cond[:var1]
          a.var2 = cond[:var2]
          a.binaryoperator = cond[:binaryoperator].to_s #plus or minus
          a.comparator = cond[:comparator].to_s #less_than, greater_than etc.
          regex = Regexp.new(/.count/)
          matchdata = regex.match(a.var1) 
          if matchdata
            a.const_value = (cond[:const_value] - 1 )
          else 
            a.const_value = cond[:const_value]
          end
          
          # a.const_value = cond[:const_value]
          if(a.comparator == "less_than")
            a.comparator = :<
          elsif(a.comparator == "less_than_equal")
            a.comparator = :<=
          elsif(a.comparator == "greater_than")
            a.comparator = :>
          elsif(a.comparator == "greater_than_equal")
            a.comparator = :>=
          elsif( (a.comparator == "equal1") or (a.comparator == "equal2") or (a.comparator == "equal") )
            a.comparator = :==
          elsif( (a.comparator == "not1") or (a.comparator == "not2") or (a.comparator == "not") )
            a.comparator = "!=".to_sym
          else
            a.comparator = :UNKNOWN_COMPARATOR
          end
          
          if(a.binaryoperator == "plus" or a.binaryoperator == "+")
            a.binaryoperator = :+
          elsif(a.binaryoperator == "minus" or a.binaryoperator == "-")
            a.binaryoperator = :-
          else
            a.binaryoperator = :UNKOWN_BINARY_OPERATOR
          end

          a.validator = Proc.new{|obj| #obj is effectively an object of model_name class
            if((a.var2 == nil) or (a.var2 == 0))#single variable has to be handled
              #var1 is a string
              obj1 = a.var1.split(".").map{|x| x.to_sym}.inject(obj){|s,x|
                s.send(x) if s!= nil
              }
              if obj1 == nil
                false #this has happend when the condition is ill-formed (say wrong spelling)
              elsif a.comparator == "!=".to_sym
                obj1 != a.const_value
              else#otherwise
                obj1.send(a.comparator, a.const_value)
              end
            else #two variables to be handled
              #get obj1
              obj1 = a.var1.split(".").map{|x| x.to_sym}.inject(obj){|s,x|
                s.send(x) if s!= nil
              }
              next if obj1 == nil #this can happend when the condition is ill-formed (say wrong spelling)

              #get obj2
              obj2 = a.var2.split(".").map{|x| x.to_sym}.inject(obj){|s,x|
                if s!= nil then s.send(x) end
              }
              next if obj2 == nil #this can happend when the condition is ill-formed (say wrong spelling)
              
              obj3 = obj1.send(a.binaryoperator, obj2)
              obj3 != a.const_value if a.comparator == "!=".to_sym
              #otherwise
              if obj3.class == Rational
                obj3.send(a.comparator, a.const_value.to_i)
              else
                obj3.send(a.comparator, a.const_value)
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
      
      def self.get_condition(cond)
        if((cond[:linking_operator] != nil) and (cond[:linking_operator].to_sym == :not)) then
          c = ComplexCondition.new
          c.operator = :not
          c.condition1 = ComplexCondition.get_condition(cond[:first_condition])
          c.condition2 = nil
          c.is_basic_condition = false
          return c
        elsif((cond[:linking_operator] != nil) and (cond[:linking_operator].to_sym == :and) || (cond[:linking_operator].to_sym == :or)) then
          c = ComplexCondition.new
          c.operator = cond[:linking_operator]
          c.condition1 = ComplexCondition.get_condition(cond[:first_condition])
          c.condition2 = ComplexCondition.get_condition(cond[:second_condition])
          c.is_basic_condition = false
          return c
        else
          c = ComplexCondition.new
          c.is_basic_condition = true
          c.basic_condition = BasicCondition.get_basic_condition(cond)
          return c
        end
      end
      
      def check_condition(obj)
        if is_basic_condition
          return @basic_condition.validator.call(obj)
        elsif operator == :not
          return (not @condition1.check_condition(obj))
        elsif operator == :and or operator == "and"
          return (@condition1.check_condition(obj) && @condition2.check_condition(obj))
        elsif operator == :or or operator == "or"
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
        begin 
          Rule.all.each do |r|
            r.apply_rule
          end
        rescue Exception => e#TODO find a better way of handling situation when rules table is missing
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
          return obj.blank? ? nil : Date.parse(obj)
        elsif type== "int"
          return obj.to_i
        elsif type== "float"
          return obj.to_f
        else
          return obj
        end
      end
      
      def self.apply_rule(rule)
        h = {:name => rule[:name], :on_action => rule[:on_action], :model_name => rule[:model_name], 
          :permit => rule[:permit], :condition => convert_to_polish_notation(rule[:condition]),
          :precondition => convert_to_polish_notation(rule[:precondition]),
          :active => rule[:active] }
        self.add h
      end
      
      #this is used for converting condition and precondition to polish notation
      def self.convert_to_polish_notation(marshalled_condition)
        condition1 = Hash.new
        if marshalled_condition == nil
          return condition1 #blank
        end
        Marshal.restore(marshalled_condition).to_a.reverse!.each do |idx, cond|
          var2 = nil
          if cond[:variable]["2"] != nil
            var2 = cond[:variable]["2"][:complete]
          end
          if (var2 != nil) and (var2 == "0")
            var2 = 0 #now this can be generically handled with all cases of int and date
          end
          const_value = 0
          if (cond[:valuetype] == "date") and (var2 != 0)#this implies that var1 and var2 both are date, so a date subtraction is going on, so const_value has to be int
            const_value = get_value_obj(cond[:const_value], "int")
          else
            const_value = get_value_obj(cond[:const_value], cond[:valuetype])
          end
          condition_expression = {
            :var1 => cond[:variable]["1"][:complete],
            :binaryoperator => cond[:binaryoperator],
            :var2 => var2,
            :comparator => cond[:comparator].to_s,
            :const_value => const_value }
          if cond[:linking_operator] != ""
            hash1 = Hash.new
            hash1[:second_condition] = condition1.dup
            hash1[:linking_operator] = cond[:linking_operator]
            #condition format - Variable1, binary opearator(+/-), Variable2, comparator, const_value
            hash1[:first_condition]= condition_expression
            condition1 = hash1
          elsif
            condition1 = condition_expression
          end
        end
        return condition1
      end
      
      #should not be called directly
      #only apply_rule should call this func
      def self.add(hash)
        if(hash[:model_name].class != Class)
          hash[:model_name] = Kernel.const_get(hash[:model_name].camelcase)
        end
        function_name = hash[:name].to_s.downcase.gsub(" ", "_")
        hash[:model_name].send(:define_method, function_name) do
          # no need to match the rule if it is not active
          return true unless hash[:active]

          if hash.key?(:permit)
            if(hash[:permit] == "false")
              hash1 = {:linking_operator => :not, :first_condition => hash[:condition].dup}
              hash[:condition] = hash1
            end
          end
          if hash.key?(:precondition) and hash[:precondition].length != 0 #result = not precondition OR (precondition AND condition)
            c = hash[:condition].dup
            p = hash[:precondition].dup
            hash[:condition] = {:linking_operator => :or,
              :first_condition => {:linking_operator =>:not, :first_condition => p}, 
              :second_condition => {:linking_operator =>:and, :first_condition => p, 
                :second_condition => c } }
          end          
          c = ComplexCondition.get_condition(hash[:condition])
          if c.check_condition(self)
            return true
          else
            return [false, "#{hash[:name]} violated"]
          end
        end
        opts = {}
        if hash[:on_action] == :update
          opts[:unless] = :new?
        elsif hash[:on_action] == :create
          opts[:if] = :new?
        elsif hash[:on_action] == :destroy
          opts[:when] = :destroy
        end
        return hash[:model_name].descendants.to_a.map{|model| model.validates_with_method(function_name, opts)}
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
        hash[:name] = hash[:name].to_s.downcase.gsub(" ", "_")        
        if hash[:model_name].new.respond_to?(hash[:name])
          hash[:model_name].send(:define_method, hash[:name]) do
            return true #overwrite the old function
          end
          return true
        else
          return false
        end
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

