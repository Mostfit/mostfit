class GraphData < Application

  def loan(id)
    @loan      = Loan.get(id)
    max_amount = @loan.total_to_be_received
    dates      = @loan.installment_dates
    offset     = 0

    d = @loan.shift_date_by_installments(dates.min, -1)
    while d >= @loan.disbursal_date
      offset += 1
      dates  << d
      d = @loan.shift_date_by_installments(d, -1)
    end

    step_size = 1; i = 0   # make a nice round step size, not more than 20 steps
    while dates.size/step_size > 20
      step_size = [1, 5, 10, 20, 50, 100, 200, 500, 1000][i += 1]
    end

    @labels, @stacks = [], []
    dates.sort.each_with_index do |date, index|
      future               = date > Date.today
      schduled_outstanding = @loan.scheduled_outstanding_total_on(date)  # or *_principal_on
      actual_outstanding   = future ? schduled_outstanding : @loan.actual_outstanding_total_on(date)  # or *_principal_on
      overpaid             = schduled_outstanding - actual_outstanding  # negative means shortfall
      tip_base             = "##{index+1}, #{date.strftime("%a %b %d %Y")}#{(future ? ' (future)' : '')}<br>"
      percentage           = (overpaid.abs.to_f/@loan.total_to_be_received*100).round.to_s + '%'
      @stacks << [
        { :val => [schduled_outstanding, actual_outstanding].min, :colour => (future ? '#55aaff' : '#003d4a'),
          :tip => tip_base },
        { :val => [overpaid,  0].max, :colour => (future ? '#55ff55' : '#00aa00'),
          :tip => "#{tip_base}#{ overpaid} (#{percentage}) overpaid" },
        { :val => [-overpaid, 0].max, :colour => (future ? '#ff5588' : '#aa0000'),
          :tip => "#{tip_base}#{-overpaid} (#{percentage}) shortfall" } ]
      @labels << ((index % step_size == 0 and index > offset) ? (index-offset+1).to_s : '')
    end
    render_loan_graph('installments', @stacks, @labels, step_size, max_amount)
  end


  def client(id)
    @client    = Client.get(id)
#     return loan(@client.loans.first.id) if @client.loans.size == 1  # nicely prints on the installment dates
    start_date = @client.loans.min(:scheduled_disbursal_date)
    end_date   = (@client.loans.map { |l| l.last_loan_history_date }).max
    loan_ids   = @client.loans.all(:fields => [:id]).map { |x| x.id }
    common_aggregate_loan_graph(loan_ids, start_date, end_date)
  end

  def center(id)
    @center    = Center.get(id)
    start_date = @center.clients.loans.min(:scheduled_disbursal_date)
    end_date   = Date.today  # (@client.loans.map { |l| l.last_loan_history_date }).max
    loan_ids   = @center.clients.loans.all(:fields => [:id]).map { |x| x.id }
    common_aggregate_loan_graph(loan_ids, start_date, end_date)
  end

  def branch(id)
    @branch    = Branch.get(id)
    start_date = @branch.centers.clients.loans.min(:scheduled_disbursal_date)
    end_date   = Date.today  # (@client.loans.map { |l| l.last_loan_history_date }).max
    loan_ids   = @branch.centers.clients.loans.all(:fields => [:id]).map { |x| x.id }
    common_aggregate_loan_graph(loan_ids, start_date, end_date)
  end

  def total
    start_date = Loan.all.min(:scheduled_disbursal_date)
    end_date   = Date.today  # (@client.loans.map { |l| l.last_loan_history_date }).max
    loan_ids   = Loan.all(:fields => [:id]).map { |x| x.id }
    common_aggregate_loan_graph(loan_ids, start_date, end_date)
  end

  def common_aggregate_loan_graph(loan_ids, start_date, end_date)
    days = (end_date - start_date).to_i
    step_size = 1; i = 0   # make a nice round step size, not more than 20 steps
    while days/step_size > 40
      step_size = [1, 7, 14, 30, 60, 365/4, 365/2, 365][i += 1]
    end
    steps = days/step_size + 1
    dates = []
    steps.times { |i| dates << start_date + step_size * i }

    @labels, @stacks, max_amount = [], [], 0
    dates.each_with_index do |date, index|
      s                     = LoanHistory.sum_outstanding_for(date, loan_ids)
      scheduled_outstanding = (s['scheduled_outstanding_total'] or 0)  # or *_principal
      actual_outstanding    = (s['actual_outstanding_total'] or 0)     # or *_principal
      max_amount            = [max_amount, scheduled_outstanding, actual_outstanding].max
      overpaid              = scheduled_outstanding - actual_outstanding  # negative means shortfall
      future                = date > Date.today
      tip_base              = "##{index+1}, #{date.strftime("%a %b %d %Y")}#{(future ? ' (future)' : '')}<br>"
      percentage            = (max_amount == 0 ? '0' : (overpaid.abs.to_f/max_amount*100).round.to_s) + '%'
      @stacks << [
        { :val => [scheduled_outstanding, actual_outstanding].min, :colour => (future ? '#55aaff' : '#003d4a'),
          :tip => tip_base },
        { :val => [overpaid,  0].max, :colour => (future ? '#55ff55' : '#00aa00'),
          :tip => "#{tip_base}\n#{ overpaid} overpaid (#{percentage})" },
        { :val => [-overpaid, 0].max, :colour => (future ? '#ff5588' : '#aa0000'),
          :tip => "#{tip_base}\n#{-overpaid} shortfall (#{percentage})" } ]
      @labels << ((index % step_size == 0) ? date.strftime("%b%d'%y") : '')
    end
    render_loan_graph('aggregate loan graph', @stacks, @labels, step_size, max_amount)
  end



  def render_loan_graph(description, stacks, labels, step_size, max_amount)
    <<-JSON
    { "elements": [ { 
        "type": "bar_stack", 
        "colours": [ "#666666", "#00aa00", "#aa0000" ], 
        "values": #{stacks.to_json}, 
        "keys": [ 
          { "colour": "#aa0000", "text": "shortfall", "font-size": 10 },
          { "colour": "#ff5588", "text": "shortfall (future)", "font-size": 10 },
          { "colour": "#00aa00", "text": "overpaid", "font-size": 10 },
          { "colour": "#55ff55", "text": "overpaid (future)", "font-size": 10 } ] } ],
      "x_axis": {
        "steps":        #{step_size},
        "colour":       "#333333",
        "grid-colour":  "#ffffff",
        "labels":       { "labels": #{labels.to_json}} },
      "x_legend":       { "text": "#{description}", "style": "{font-size: 11px; color: #003d4a; font-weight: bold;}" },
      "y_axis": {
        "colour":       "#333333",
        "grid-colour":  "#bc6624",
        "steps":        #{max_amount/8},
        "min":          0,
        "max":          #{max_amount + max_amount/7} },
      "bg_colour":      "#ffffff",
      "tooltip":        {
        "mouse":        2,
        "stroke":       2,
        "colour":       "#333333",
        "background":   "#fbf8f1",
        "title":        "{font-size: 12px; font-weight: bold; color: #003d4a;}",
        "body":         "{font-size: 10px; font-weight: bold; color: #000000;}" } }
    JSON
  end

end
