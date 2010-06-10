module Merb
  module Business
    class Symbol
      def method_missing
        puts "hi"
      end
    end
    
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
            
      def self.prepare(&blk)
        self.new.instance_eval(&blk)
      end
      
      def allow(hash)
        condition = get_condition(hash)
        hash[:model].validates_with_method()       
        print "Allow a #{hash[:model]} object on #{hash[:on]} if 'object.#{condition}'"
        print " subject to a precondition of #{hash[:if]}" if hash.key?(:if)
        puts
      end
      
      def reject(hash)
        condition = get_condition(hash)
        print "Reject a #{hash[:model]} object on #{hash[:on]} if 'obj.#{condition}'"
        print " subject to a precondition of #{hash[:if]}" if hash.key?(:if)
        puts
      end
      
      def self.rules
        @@rules
      end

      private
      def get_condition(hash)
        if hash[:condition].class==Array
          hash[:condition][1] = "<"  if hash[:condition][1] == :less_than
          hash[:condition][1] = "<=" if hash[:condition][1] == :less_than_equal
          hash[:condition][1] = ">"  if hash[:condition][1] == :greater_than
          hash[:condition][1] = ">=" if hash[:condition][1] == :greater_than_equal
          hash[:condition][1] = "==" if hash[:condition][1] == :equal
          condition = hash[:condition].join(" ")
        elsif hash[:condition].class==Hash
          condition = hash[:condition].to_a.join(" => ")
        end
        condition
      end

    end
  end    
end    

