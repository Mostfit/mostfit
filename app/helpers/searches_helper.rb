module Merb
  module SearchesHelper
    def model_names
      (DataMapper::Model.descendants).reject{|x| 
        x.ancestors.include?(Loan) or x.ancestors.include?(Report) or [Mfi, ActionLog, AuditTrail, Cgt, Comment, LedgerEntry].include?(x)
      }.map{|d| 
        [d.to_s.snake_case.to_sym, d.to_s]
      }.sort_by{|x| x[1]}
    end
  end
end # Merb
