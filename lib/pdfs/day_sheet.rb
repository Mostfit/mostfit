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
        pdf.text("Date: #{@date}, Time: #{center.meeting_time_hours}:#{'%02d' % center.meeting_time_minutes}", :font_size => 12, :justification => :left)
        pdf.text("\n")
        table = PDF::SimpleTable.new
        table.data = []
        tot_amount, tot_outstanding, tot_installments, tot_principal, tot_interest, total_due = 0, 0, 0, 0, 0, 0
        #Prefecth some data for speed
        loans = center.loans
        histories = LoanHistory.all(:loan_id => loans.map{|x| x.id}, :date => @date)
        fees_applicable = Fee.due(loans.map{|x| x.id})
        tot_amount, tot_outstanding, tot_installments, tot_principal, tot_interest, tot_fee, tot_total = 0, 0, 0, 0, 0, 0, 0

        #grouping by client groups
        center.clients(:fields => [:id, :name]).group_by{|x| x.client_group}.sort_by{|x| x[0] ? x[0].name : "none"}.each{|group, clients|
          group_amount, group_outstanding, group_installments, group_principal, group_interest, group_fee, group_due = 0, 0, 0, 0, 0, 0, 0
          table.data.push({"disbursed on" => "#{group.name}"})
          #Grouped clients
          clients.sort_by{|x| x.name}.each{|client|
            # all the loans of a client
            loan_row_count=0
            loans.find_all{|l| l.client_id==client.id and l.disbursal_date}.each{|loan|
              lh = histories.find_all{|x| x.loan_id==loan.id}.sort_by{|x| x.created_at}[-1]
              next if not lh
              loan_row_count+=1
              fee = fees_applicable[loan.id] ? fees_applicable[loan.id].due : 0
              actual_outstanding = (lh ? lh.actual_outstanding_principal : 0)
              principal_due      = [(lh ? lh.principal_due : 0), 0].max
              interest_due       = [(lh ? lh.interest_due : 0), 0].max
              total_due          = [(lh ? (fee+lh.principal_due+lh.interest_due): 0), 0].max
              number_of_installments = loan.number_of_installments_before(@date)
              
              table.data.push({"on name" => client.name, "loan id" => loan.id, "amount" => loan.amount.to_currency, 
                                "outstanding" => actual_outstanding.to_currency,
                                "status" => lh.status.to_s,
                                "disbursed on" => loan.disbursal_date.to_s, 
                                "installment" =>  number_of_installments,
                                "principal due" => principal_due.to_currency, 
                                "interest due" => interest_due.to_currency,
                                "fee"          => fee.to_currency,
                                "total due" =>  total_due.to_currency,
                                "attendance" => ""
                              })
              group_amount       += loan.amount
              group_outstanding  += actual_outstanding
              group_installments += number_of_installments
              group_principal    += principal_due
              group_interest     += interest_due
              group_fee          += fee
              group_due          += total_due
            } # loans end
            if loan_row_count==0
              table.data.push({"on name" => client.name, "status" => "nothing outstanding"})              
            end
          } #clients end
          table.data.push({"amount" => group_amount.to_currency, "outstanding" => group_outstanding.to_currency,
                            "principal due" => group_principal.to_currency, "interest due" => group_interest.to_currency,
                            "fee" => group_fee.to_currency, "total due" => group_due.to_currency                            
                          })
          tot_amount         += group_amount
          tot_outstanding    += group_outstanding
          tot_installments   += group_installments
          tot_principal      += group_principal
          tot_interest       += group_interest
          tot_fee            += group_fee
          total_due          += (group_principal + group_interest + group_fee)
        } #groups end
        table.data.push({"amount" => tot_amount.to_currency, "outstanding" => tot_outstanding.to_currency,
                          "principal due" => tot_principal.to_currency,
                          "interest due" => tot_interest.to_currency, "fee" => tot_fee.to_currency,
                          "total due" => (tot_principal + tot_interest + tot_fee).to_currency
                        })
        
        table.column_order  = ["on name","loan id","amount","outstanding","status", "disbursed on", "installment","principal due","interest due","fee", "total due", "attendance"]
        table.show_lines    = :all
        table.show_headings = true
        table.shade_rows    = :none
        table.shade_headings = true
        table.orientation   = :center
        table.position      = :center
        table.title_font_size = 16
        table.header_gap = 10
        table.render_on(pdf)
      } #centers end
      pdf.save_as("#{Merb.root}/public/pdfs/staff_#{@staff_member.id}_#{@date.strftime('%Y_%m_%d')}.pdf")
      return pdf
    end
  end
end

#  def generate_pdf
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

