class LoanPurposeReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id, :staff_member_id, :loan_product_id, :funder_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.min_date
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today  
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end
  
  def name
    "Loan Purpose Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Loan purpose report"
  end
  
  def generate
    branches, centers, data, occupations, clients = {}, {}, {}, {}, {}
    extra     = []
    extra    << "l.loan_product_id = #{loan_product_id}" if loan_product_id
    # if a funder is selected
    if @funder
      funder_loan_ids = @funder.loan_ids
      extra    << "l.id in (#{funder_loan_ids.join(", ")})" 
    end

    histories = LoanHistory.sum_outstanding_grouped_by(to_date, ["occupation", "branch"], extra).group_by{|x| x.branch_id}
    Occupation.all.each{|p| occupations[p.id]=p}

    @branch.each{|b|
      data[b]||= {}
      branches[b.id] = b
      next unless histories.key?(b.id)
      histories[b.id].each{|history|
        occupation = occupations[history.occupation_id]
        data[b][occupation] = [0, 0, 0, 0]
        data[b][occupation][2] += history.loan_count
        data[b][occupation][3] += history.actual_outstanding_principal
      }
    }

    #3: Disbursal date
    hash = {:disbursal_date.gte => from_date, :disbursal_date.lte => to_date, :rejected_on => nil}
    hash[:loan_product_id] = self.loan_product_id if self.loan_product_id
    hash["l.id"]           = funder_loan_ids if funder_loan_ids and funder_loan_ids.length > 0

    group_loans(["l.occupation_id", "c.branch_id"], "SUM(l.amount) amount, COUNT(l.id) count", hash).group_by{|x| x.branch_id}.each{|branch_id, loan_occupations|
      next unless branches.key?(branch_id)
      branch  = branches[branch_id]
      loan_occupations.group_by{|x| x.occupation_id}.each{|occupation_id, loans|
        occupation = occupations[occupation_id]
        if loans.length>0
          data[branch][occupation] ||= [0, 0, 0, 0]
          data[branch][occupation][0] += loans.first.count
          data[branch][occupation][1] += loans.first.amount
        end
      }
    }
    return data
  end
end
