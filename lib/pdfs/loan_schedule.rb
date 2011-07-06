module Pdf
  module LoanSchedule

    def generate_loan_schedule
      loan_history = self.loan_history
      return nil if loan_history.empty?
      pdf =  PDF::Writer.new(:orientation => :portrait, :paper => "A4")
      pdf.select_font "Times-Roman"
      pdf.text "Repayment Schedule of Loan ID #{self.id} for client #{self.client.name} (ID: #{self.client.id})", :font_size => 18, :justification => :center
      pdf.text("\n")
      client_info = PDF::SimpleTable.new
      client_info.data = []
      client_info.data.push({ "identifier" => "Amount Applied", "value" => "#{self.amount_applied_for.to_currency } by #{self.applied_by.name} on #{self.applied_on.strftime("%d-%m-%Y")}"})
      if not self.approved_on.nil?
        client_info.data.push({ "identifier" => "Amount Sanctioned", "value" => "#{self.amount_sanctioned.to_currency} by #{self.approved_by.name} on #{self.approved_on.strftime("%d-%m-%Y")}"}) 
      end
      if not self.disbursal_date.nil?
        client_info.data.push({ "identifier" => "Amount Disbursed", "value" => "#{self.amount.to_currency} by #{self.disbursed_by.name} on #{self.disbursal_date.strftime("%d-%m-%Y")}"}) 
      end
      client_info.data.push({ "identifier" => "Loan Product", "value" => self.loan_product.name },
                            { "identifier" => "Loan Type", "value" => self.type.to_s }
                            )
      self.applicable_fees.each_with_index do |fee, idx|
        client_info.data.push({ "identifier" => "Fee #{idx + 1}", "value" => "#{Fee.get(fee.fee_id).name} of amount #{fee.amount} applicable on #{fee.applicable_on.strftime("%d-%m-%Y")}"})
      end
      client_info.column_order  = ["identifier", "value"]
      client_info.show_lines    = :none
      client_info.show_headings = false
      client_info.shade_rows    = :none
      client_info.shade_headings = false
      client_info.orientation   = :center
      client_info.position      = :center
      client_info.title_font_size = 13
      client_info.header_gap = 10
      client_info.render_on(pdf)
      pdf.text("\n")
      table = PDF::SimpleTable.new
      table.data = []
      loan_history.each_with_index do |lh, i|
        scheduled_principal = lh[:scheduled_principal_to_be_paid] == 0 ? (i > 0 ? loan_history[i-1].scheduled_outstanding_principal - lh.scheduled_outstanding_principal : 0) : lh[:scheduled_principal_to_be_paid]
        scheduled_interest =  lh[:scheduled_interest_to_be_paid] == 0 ? (i > 0 ? loan_history[i-1].scheduled_outstanding_total - lh.scheduled_outstanding_total - scheduled_principal : 0) : lh[:scheduled_interest_to_be_paid]
        table.data.push({"Date Due" => lh.date, "Scheduled Balance" => lh.scheduled_outstanding_principal.to_currency, 
                          "Scheduled Principal" => scheduled_principal.to_currency,
                          "Scheduled Interest" => scheduled_interest.to_currency, 
                          "Scheduled Total" => (scheduled_principal + scheduled_interest).to_currency,
                          "RO Signature" => "",
                        })
        # if 
        # table.data.push({ "actual balance" => "",
        #                   "actual repayments"  => ""
        #                 })
        # end
      end
      table.column_order  = ["Date Due", "Scheduled Balance", "Scheduled Principal", "Scheduled Interest", "Scheduled Total", "RO Signature"]
      table.show_lines    = :all
      table.show_headings = true
      table.shade_rows    = :none
      table.shade_headings = true
      table.orientation   = :center
      table.position      = :center
      table.title_font_size = 14
      table.header_gap = 10
      table.render_on(pdf)
      return pdf
    end
  end
  
end
