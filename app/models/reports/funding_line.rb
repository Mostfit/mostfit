module Reporting
  module FundingLineReports
    def query_as_hash(sql)
      repository.adapter.query(sql).map {|x| [x[0],x[1]]}.to_hash
    end
    
    
  end
end
