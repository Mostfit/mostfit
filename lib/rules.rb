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
          a.operator = :-
          a.compareWith = -1

          a.appliesOn = arr[0]
          a.operator = :<  if arr[1] == :less_than
          a.operator = :<= if arr[1] == :less_than_equal
          a.operator = :>  if arr[1] == :greater_than
          a.operator = :>= if arr[1] == :greater_than_equal
          a.operator = :== if arr[1] == :equal
          a.operator = "!=".to_sym if arr[1] == :not
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

    class Condition
      attr_accessor :is_basic_condition , :basic_condition #makes sense only if its a basic condition
      attr_accessor :operator #makes sense only if its not a basic condition
      attr_accessor :condition1, :condition2 #makes sense only if its not a basic condition

      def self.get_condition(arr)
        if(arr[0] == :not) then
          c = Condition.new
          c.operator = :not
          c.condition1 = Condition.get_condition(arr[1])
          c.condition2 = nil
          c.is_basic_condition = false
          return c
        elsif((arr[0] == :and) || (arr[0] == :or)) then
          c = Condition.new
          c.operator = arr[0]
          c.condition1 = Condition.get_condition(arr[1])
          c.condition2 = Condition.get_condition(arr[2])
          c.is_basic_condition = false
          return c
        else
          c = Condition.new
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
        load(File.join(Merb.root, "config", "rules.rb"))
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

      def self.add(hash)
        hash[:model].send(:define_method, hash[:name]) do
          puts "#{hash[:name]} called"
          if hash.key?(:precondition) #result = not precondition OR (precondition AND condition)
            hash[:condition] = [:or, [:not, hash[:precondition]], 
              [:and, hash[:precondition], hash[:condition]] ]
          end
          c = Condition.get_condition(hash[:condition])
          #puts c.to_s
          if c.check_condition(self) then
            return true
          else
            puts "#{hash[:name]} violated"
            return [false, "#{hash[:name]} violated"]
          end
        end
        hash[:model].validates_with_method(hash[:name])
      end

      #to remove a validation
      def self.remove(hash)
        if hash[:model].new.respond_to?(hash[:name])
          hash[:model].send(:define_method, hash[:name]) do
            return true #overwrite the old function
          end
        end
      end

      #deprecated
      def allow(hash)
        
        validator = get_condition(hash)
        hash[:model].send(:define_method, hash[:name]) do
          if hash.key?(:precondition)
            return true if hash[:precondition] and validator.call(self)
          else
            return true if validator.call(self)
          end
          return [false, "#{hash[:name]} violated"]
        end
        hash[:model].validates_with_method(hash[:name])
      end

      #deprecated      
      def reject(hash)
        #TODO
#        validator = get_condition(hash)
#        hash[:model].send(:define_method, hash[:name]) do
#          if hash.key?(:precondition)
#            return [false, "#{hash[:name]} violated"] if hash[:precondition] and validator.call(self)
#          else
#            return [false, "#{hash[:name]} violated"] if hash[:precondition] and validator.call(self)
#          end
#          return true
#        end
#        hash[:model].validates_with_method(hash[:name], :when => hash[:on])
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
        #elsif hash[:condition].class==Hash
        #  validator = hash[:condition].to_a.join(" => ")
        end
        validator
      end
    end
  end    
end    

