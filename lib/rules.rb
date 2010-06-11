module Mostfit
  module Business
    class Rule
      @@rules = {}
      REJECT_REGEX = /^(Merb|merb)::*/
      
      def self.deploy
        load(File.join(Merb.root, "config", "rules.rb"))
      end

      def initialize
      end
      
      def all_models
        DataMapper::Model.descendants.map{|d| d.to_s.snake_case.to_sym}
      end

      def self.tree
        DataMapper::Model.descendants.to_a.collect{|m| 
          {m => m.relationships}
        }.inject({}){|s,x| s+=x}.reject{|k,v| v.length==0}
      end
            
      def self.prepare(&blk)
        self.new.instance_eval(&blk)
      end
      
      def allow(hash)
        validator = get_condition(hash)
        hash[:model].send(:define_method, hash[:name]) do
          if hash.key?(:if)
            return true if hash[:if] and validator.call(self)
          else
            return true if validator.call(self)
          end
          return [false, "#{hash[:name]} violated"]
        end
        hash[:model].validates_with_method(hash[:name])
      end
      
      def reject(hash)
        validator = get_condition(hash)
        hash[:model].send(:define_method, hash[:name]) do
          if hash.key?(:if)
            return [false, "#{hash[:name]} violated"] if hash[:if] and validator.call(self)
          else
            return [false, "#{hash[:name]} violated"] if hash[:if] and validator.call(self)
          end
          return true
        end
        hash[:model].validates_with_method(hash[:name], :when => hash[:on])
      end
      
      def self.rules
        @@rules
      end

      private
      def get_condition(hash)
        if hash[:condition].class==Array
          hash[:condition][1] = :<  if hash[:condition][1] == :less_than
          hash[:condition][1] = :<= if hash[:condition][1] == :less_than_equal
          hash[:condition][1] = :>  if hash[:condition][1] == :greater_than
          hash[:condition][1] = :>= if hash[:condition][1] == :greater_than_equal
          hash[:condition][1] = :== if hash[:condition][1] == :equal
          validator = Proc.new{|obj|
            hash[:condition][0].split(".").map{|x| 
              x.to_sym
            }.inject(obj){|s,x| 
              s.send(x)
            }.send(hash[:condition][1], hash[:condition][2])
          }
        elsif hash[:condition].class==Hash
          validator = hash[:condition].to_a.join(" => ")
        end
        validator
      end
    end
  end    
end    

