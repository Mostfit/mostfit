module Pdf
  module DaySheet
    def generate_pdf
      pdf = PDF::Writer.new(:orientation => :landscape)
      pdf.select_font "Times-Roman"
      pdf.text "Day sheet for #{@staff_member.name} for #{@date}", :font_size => 30, :justification => :center    
      @centers.each{|center|
        pdf.start_new_page                
        table = PDF::SimpleTable.new
        table.title = "Center name: #{center.name}"
        table.data = []
        tot_amount, tot_outstanding, tot_installments, tot_principal, tot_interest, total_due = 0, 0, 0, 0, 0, 0
        
        center.clients.each{|client|
          client.loans.each{|loan|
            table.data.push({"on name" => loan.client.name, "id" => loan.id, "amount" => loan.amount.to_currency, 
                              "outstanding" => loan.actual_outstanding_principal_on(@date).to_currency,
                              "status" => loan.get_status(@date).to_s, "disbursed on" => loan.disbursal_date.to_s, "funder" => loan.funder_name,
                              "installment" => loan.number_of_installments_before(@date), "principal due" => [-loan.principal_overpaid_on(@date), 0].max.to_currency,
                              "interest due" => [-loan.interest_overpaid_on(@date), 0].max.to_currency,
                              "total due" => [-loan.total_overpaid_on(@date), 0].max.to_currency
                            })
            tot_amount       += loan.amount
            tot_outstanding  += loan.actual_outstanding_principal_on(@date)
            tot_installments += loan.number_of_installments_before(@date)
            tot_principal    += [-loan.principal_overpaid_on(@date), 0].max
            tot_interest     += [-loan.interest_overpaid_on(@date), 0].max
            total_due        += [-loan.total_overpaid_on(@date), 0].max            
          }
        }
        table.data.push({"amount" => tot_amount.to_currency, "outstanding" => tot_outstanding.to_currency,
                          "installment" => tot_installments.to_currency, "principal due" => tot_principal.to_currency,
                          "interest due" => tot_interest.to_currency,
                          "total due" => total_due.to_currency
                        })

        table.column_order  = ["on name","id","amount","outstanding","status", "disbursed on", "funder", "installment","principal due","interest due", "total due"]
        table.show_lines    = :all
        table.show_headings = true
        table.orientation   = :center
        table.position      = :center
        table.title_font_size = 16
        table.header_gap = 10
        table.render_on(pdf)
      }
      pdf.save_as("#{Merb.root}/public/pdfs/staff_#{@staff_member.id}_#{@date}.pdf")
      return pdf
    end
  end
end
