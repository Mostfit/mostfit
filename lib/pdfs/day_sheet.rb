module Pdf
  module DaySheet
    def generate_pdf
      pdf = PDF::Writer.new(:orientation => :landscape)
      pdf.select_font "Times-Roman"
      pdf.text "Day sheet for #{@staff_member.name} for #{@date}", :font_size => 24, :justification => :center
      pdf.text("\n")
      @centers.sort_by{|x| x.meeting_time_hours + x.meeting_time_hours}.each_with_index{|center, idx|
        pdf.start_new_page if idx > 0
        pdf.text "Center: #{center.name}, Manager: #{@staff_member.name}, signature: ______________________", :font_size => 12, :justification => :left
        pdf.text("Center leader: #{center.leader.client.name}, signature: ______________________", :font_size => 12, :justification => :left) if center.leader
        pdf.text("Date: #{@date}, Time: #{center.meeting_time_hours}:#{center.meeting_time_minutes}", :font_size => 12, :justification => :left)
        pdf.text("\n")
        table = PDF::SimpleTable.new
        table.data = []
        tot_amount, tot_outstanding, tot_installments, tot_principal, tot_interest, total_due = 0, 0, 0, 0, 0, 0
        
        center.clients.group_by(&:client_group_id).each{|groups|
          group_amount, group_outstanding, group_installments, group_principal, group_interest, group_due = 0, 0, 0, 0, 0, 0
          table.data.push({"disbursed on" => "#{ClientGroup.get(groups[0].to_i).name}"})
          groups[1].each{|client|
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
              group_amount       += loan.amount
              group_outstanding  += loan.actual_outstanding_principal_on(@date)
              group_installments += loan.number_of_installments_before(@date)
              group_principal    += [-loan.principal_overpaid_on(@date), 0].max
              group_interest     += [-loan.interest_overpaid_on(@date), 0].max
              group_due          += [-loan.total_overpaid_on(@date), 0].max                        
            }
          }
          table.data.push({"amount" => group_amount.to_currency, "outstanding" => group_outstanding.to_currency,
                          "installment" => group_installments.to_currency, "principal due" => group_principal.to_currency,
                          "interest due" => group_interest.to_currency,
                          "total due" => group_due.to_currency
                          })
        }
        table.data.push({"amount" => tot_amount.to_currency, "outstanding" => tot_outstanding.to_currency,
                          "installment" => tot_installments.to_currency, "principal due" => tot_principal.to_currency,
                          "interest due" => tot_interest.to_currency,
                          "total due" => total_due.to_currency
                        })

        table.column_order  = ["on name","id","amount","outstanding","status", "disbursed on", "funder", "installment","principal due","interest due", "total due"]
        table.show_lines    = :all
        table.show_headings = true
        table.shade_rows    = :none
        table.shade_headings = true
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

#  def generate_pdf
#    debugger
#    pdf = PDF::HTMLDoc.new
#    pdf.set_option :bodycolor, :white
#    pdf.set_option :toc, false
#    pdf.set_option :portrait, true
#    pdf.set_option :links, true
#    pdf.set_option :webpage, true
#    pdf.set_option :left, '2cm'
#    pdf.set_option :right, '2cm'
#    pdf.set_option :header, "Header here!"
#    pdf.set_option :outfile, "#{Merb.root}/public/pdfs/staff_#{@staff_member.id}_#{@date}.pdf"
#    f = File.read("app/views/staff_members/day_sheet.html.haml")
#    report = Haml::Engine.new(f).render(Object.new)
#    pdf << report
#    pdf.footer ".t."
#    pdf.generate
#    pdf.save_as("#{Merb.root}/public/pdfs/staff_#{@staff_member.id}_#{@date}.pdf")
##    f = File.read("app/views/reports/_#{name.snake_case.gsub(" ","_")}.pdf.haml")
##    report = Haml::Engine.new(f).render(Object.new, :report => self)
#    return pdf
#  end

