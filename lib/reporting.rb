module Mostfit
  module Reporting

    # Column represetns a column in a report, and can have sub-columns.
    #
    #   c = Column.new('branch)
    #   c.name #=> :branch
    #
    #   c = Column.new :repayment => [{:total => [:principal, :interest]}, :fee]
    #   c.name               #=> :repayment
    #   c.columns.count      #=> 2
    #   c.columns            #=> [total: [principal, interest], fee]
    #   c.columns[0]         #=> total: [principal, interest]
    #   c.columns[0].columns #=> [principal, interest]
    #
    #   c = Mostfit::Reporting::Column.new(:loan_repayment) do
    #     column :applied
    #     column :sanctioned
    #     column :disbursed
    #   end
    #   c.to_s #=> "loan_repayment: [applied, sanctioned, disbursed]"
    class Column
      attr_reader :name

      def initialize(column, &block)
        case column
        when Symbol, String
          @name = column
        when Hash
          column.each do |name, column|
            @name = name
            column.each{|c| column(c)}
          end
        end
        if block_given?
          block.arity == 1 ? yield(self) : instance_eval(&block)
        end
      end

      def columns
        @columns ||= []
      end

      def column(column, &block)
        columns << Column.new(column, &block)
      end

      # Returns number of sub-columns, including sub-columns of sub-columns.
      # So it can be used with the html colspan attribute.
      def colspan
        if columns.empty?
          return 0
        else
          return columns.length + columns.inject(0){|s, v| s+= v.colspan}
        end
      end

      def to_s
        s = "#{name}"
        unless columns.empty?
          s << ": [#{columns.map(&:to_s).join(', ')}]"
        end
        s
      end
      alias inspect to_s
    end

    module InstanceMethods
      def columns
        self.class.columns
      end
    end

    module ClassMethods
      def columns
        @columns ||= []
      end

      def column(column, &block)
        columns << Column.new(column, &block)
      end
    end

    def self.included(klass)
      klass.extend(ClassMethods)
      klass.send(:include, InstanceMethods)
    end
  end
end
