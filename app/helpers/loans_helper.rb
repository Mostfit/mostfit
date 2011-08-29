module Merb
  module LoansHelper

    def show_history(loan)
      s = "<table class='diags'><thead><tr><th>"
      print_order = {:titles => {:date => :date, :s_total => :scheduled_outstanding_total, :s_bal => :scheduled_outstanding_principal,
            :a_total => :actual_outstanding_total, :a_bal => :actual_outstanding_principal,
            :p_paid => :principal_paid, :p_due => :principal_due, 
            :i_paid => :interest_paid, :i_due => :interest_due,
            :tot_p_pd => :total_principal_paid, :tot_i_pd => :total_interest_paid, 
            :tot_p_due => :total_principal_due, :tot_i_due => :total_interest_due,
            :tp_due => :total_principal_due, :tp_paid => :total_principal_paid, 
            :ti_due => :total_interest_due, :ti_paid => :total_interest_paid, 
            :adv_p => :advance_principal_paid, :adv_i => :advance_interest_paid, 
            :def_p => :principal_in_default, :def_i => :interest_in_default, 
            :b => :branch_id, :c => :center_id, :k => :composite_key},
        :title_order => [:date, :s_total, :a_total, :s_bal, :a_bal, :p_paid, :p_due, :i_paid, :i_due, :tp_due, :tp_paid, :ti_due, :ti_paid, :adv_p, :adv_i, :def_p, :def_i, :b, :c, :k]}
      hist = loan.calculate_history.sort_by{|x| x[:date]}
      title_order = print_order[:title_order]
      titles = print_order[:titles]
      s += title_order.map{|t| print_order[:titles][t].to_s.gsub("_"," ")}.join("</th><th>") + "</th>"
      s += "</tr></thead>"
      hist.each_with_index do |h,i|
        s += "<tr class='#{i%2 == 0 ? 'even' : 'odd'}'><td>" + (["#{h[:date]}"] + title_order[1..-1].map{|t| (h[titles[t]] || 0)}.map{|v| v.to_s}).join("</td><td>") + "</tr>"
      end
      s += "</table>"
    end

  end
end

