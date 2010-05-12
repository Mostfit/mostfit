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
        if hash[:condition].class==Array
          hash[:condition][1] = "<"  if hash[:condition][1] == :less_than
          hash[:condition][1] = "<=" if hash[:condition][1] == :less_than_equal
          hash[:condition][1] = ">"  if hash[:condition][1] == :greater_than
          hash[:condition][1] = ">=" if hash[:condition][1] == :greater_than_equal
          condition = hash[:condition].join(" ")
        elsif hash[:condition].class==Hash
          condition = hash[:condition].to_a.join(" => ")
        end
        hash[:model].validates_with_method()
        puts "Allow obj of #{hash[:model]} apply on #{hash[:on]} 'obj.#{condition}'"
      end
      
      def reject(hash)
        if hash[:condition].class==Array
          hash[:condition][1] = "<"  if hash[:condition][1] == :less_than
          hash[:condition][1] = "<=" if hash[:condition][1] == :less_than_equal
          hash[:condition][1] = ">"  if hash[:condition][1] == :greater_than
          hash[:condition][1] = ">=" if hash[:condition][1] == :greater_than_equal
          condition = hash[:condition].join(" ")
        elsif hash[:condition].class==Hash
          condition = hash[:condition].to_a.join(" => ")
        end
        puts "Reject obj of #{hash[:model]} apply on #{hash[:on]} 'obj.#{condition}'"
      end
      
      def self.rules
        @@rules
      end
    end
  end    
end    

