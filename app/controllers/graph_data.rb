class GraphData < Application

  def loan(id)
    @loan      = Loan.get(id)
    raise NotFound unless @loan.disbursal_date
    max_amount = @loan.total_to_be_received
    dates      = @loan.installment_dates
    offset     = 0

    # add dates before the first installment to include the disbursal date
    d = @loan.shift_date_by_installments(dates.min, -1)
    while d >= @loan.disbursal_date
      offset += 1
      dates  << d
      d = @loan.shift_date_by_installments(d, -1)
    end

    step_size = 1; i = 0   # make a nice round step size, not more than 20 steps
    while (dates.size + offset) / step_size > 20
      step_size = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000][i += 1]
    end

    # make sure the 1st installment has number '1' written underneath it, by adding
    # empty space at the start of the graph when needed.
    until offset % step_size == 0
      offset += 1
      dates  << @loan.shift_date_by_installments(dates.min, -1)
    end

    @labels, @stacks = [], []
    dates.sort.each_with_index do |date, index|
      future                = date > Date.today
      scheduled_outstanding = @loan.scheduled_outstanding_total_on(date)  # or *_principal_on
      actual_outstanding    = future ? scheduled_outstanding : @loan.actual_outstanding_total_on(date)  # or *_principal_on
      overpaid              = scheduled_outstanding - actual_outstanding  # negative means shortfall
      tip_base              = "##{index+1}, #{date.strftime("%a %b %d %Y")}#{(future ? ' (future)' : '')}<br>"
      percentage            = scheduled_outstanding == 0 ? '0' : (overpaid.abs.to_f/scheduled_outstanding*100).round.to_s + '%'
      @stacks << [
        { :val => [scheduled_outstanding, actual_outstanding].min, :colour => (future ? '#55aaff' : '#003d4a'),
          :tip => tip_base + (future ?
            "#{scheduled_outstanding.round} scheduled outstanding" :
            "#{actual_outstanding.round} outstanding (#{percentage} #{overpaid > 0 ? 'overpaid' : 'shortfall'})") },
        { :val => [overpaid,  0].max, :colour => (future ? '#55ff55' : '#00aa00'),
          :tip => "#{tip_base} overpaid #{ overpaid} (#{percentage})" },
        { :val => [-overpaid, 0].max, :colour => (future ? '#ff5588' : '#aa0000'),
          :tip => "#{tip_base} shortfall of #{-overpaid} (#{percentage})" } ]
      @labels << ((index % step_size == 0 and index >= offset) ? (index-offset+1).to_s : '')
    end
    render_loan_graph('installments', @stacks, @labels, step_size, max_amount)
  end


  def client(id)
    @client    = Client.get(id)
#     return loan(@client.loans.first.id) if @client.loans.size == 1  # nicely prints on the installment dates
    start_date = @client.loans.min(:scheduled_disbursal_date)
    end_date   = (@client.loans.map{|l| l.last_loan_history_date}.reject{|x| x.blank?}).max
    loan_ids   = Loan.all(:client_id => @client.id, :fields => [:id]).map { |x| x.id }
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

  def aggregate_loan_graph(loan_ids, start_date, end_date)
    days = (end_date - start_date).to_i
    step_size = 1; i = 0   # make a nice round step size, not more than 20 steps
    while days/step_size > 50
      step_size = [1, 7, 14, 30, 60, 365/4, 365/2, 365][i += 1]
    end
    steps = days/step_size + 1
    dates = []
    steps.times { |i| dates << start_date + step_size * i }
    @labels, @stacks, max_amount = [], [], 0
    table = repository.adapter.query(%Q{
      SELECT MAX(date) AS date, 
      CONCAT(WEEK(date),'_',YEAR(date)) AS weeknum, 
      SUM(scheduled_outstanding_principal),
      SUM(scheduled_outstanding_total)     AS scheduled_outstanding_total,
      SUM(actual_outstanding_principal)    AS actual_outstanding_principal,
      SUM(actual_outstanding_total)        AS actual_outstanding_total
      FROM  loan_history WHERE loan_id IN (#{loan_ids.join(', ')}) GROUP BY weeknum ORDER BY date;})
    table.each_with_index do |row,index|
      future                = row.date > Date.today
      s                     = row
      date                  = s['date']
      scheduled_outstanding = (s['scheduled_outstanding_total'].to_i or 0)  # or *_principal
      actual_outstanding    = future ? scheduled_outstanding : (s['actual_outstanding_total'].to_i or 0)     # or *_principal
      max_amount            = [max_amount, scheduled_outstanding, actual_outstanding].max
      overpaid              = scheduled_outstanding - actual_outstanding  # negative means shortfall
      tip_base              = "##{index+1}, #{date.strftime("%a %b %d %Y")}#{(future ? ' (future)' : '')}<br>"
      percentage            = scheduled_outstanding == 0 ? '0' : (overpaid.abs.to_f/scheduled_outstanding*100).round.to_s + '%'
      @stacks << [
        { :val => [scheduled_outstanding, actual_outstanding].min, :colour => (future ? '#55aaff' : '#003d4a'),
          :tip => tip_base + (future ?
            "#{scheduled_outstanding.round} scheduled outstanding" :
            "#{actual_outstanding.round} outstanding (#{percentage} #{overpaid > 0 ? 'overpaid' : 'shortfall'})") },
        { :val => [overpaid,  0].max, :colour => (future ? '#55ff55' : '#00aa00'),
          :tip => "#{tip_base} overpaid #{ overpaid} (#{percentage})" },
        { :val => [-overpaid, 0].max, :colour => (future ? '#ff5588' : '#aa0000'),
          :tip => "#{tip_base} shortfall of #{-overpaid} (#{percentage})" } ]
      @labels << ((index % step_size == 0) ? date.strftime("%b%d'%y") : '')
    end
    render_loan_graph('aggregate loan graph', @stacks, @labels, step_size, max_amount)
  end

  def common_aggregate_loan_graph(loan_ids, start_date, end_date) # __DEPRECATED__
    days = (end_date - start_date).to_i
    step_size = 1; i = 0   # make a nice round step size, not more than 20 steps
    while days/step_size > 50
      step_size = [1, 7, 14, 30, 60, 365/4, 365/2, 365][i += 1]
    end
    steps = days/step_size + 1
    dates = []
    steps.times { |i| dates << start_date + step_size * i }

    @labels, @stacks, max_amount = [], [], 0
    p dates
    dates.each_with_index do |date, index|
      future                = date > Date.today
      s                     = LoanHistory.sum_outstanding_for(date, loan_ids)[0]
      scheduled_outstanding = (s['scheduled_outstanding_total'].to_i or 0)  # or *_principal
      actual_outstanding    = future ? scheduled_outstanding : (s['actual_outstanding_total'].to_i or 0)     # or *_principal
      max_amount            = [max_amount, scheduled_outstanding, actual_outstanding].max
      overpaid              = scheduled_outstanding - actual_outstanding  # negative means shortfall
      tip_base              = "##{index+1}, #{date.strftime("%a %b %d %Y")}#{(future ? ' (future)' : '')}<br>"
      percentage            = scheduled_outstanding == 0 ? '0' : (overpaid.abs.to_f/scheduled_outstanding*100).round.to_s + '%'
      @stacks << [
        { :val => [scheduled_outstanding, actual_outstanding].min, :colour => (future ? '#55aaff' : '#003d4a'),
          :tip => tip_base + (future ?
            "#{scheduled_outstanding.round} scheduled outstanding" :
            "#{actual_outstanding.round} outstanding (#{percentage} #{overpaid > 0 ? 'overpaid' : 'shortfall'})") },
        { :val => [overpaid,  0].max, :colour => (future ? '#55ff55' : '#00aa00'),
          :tip => "#{tip_base} overpaid #{ overpaid} (#{percentage})" },
        { :val => [-overpaid, 0].max, :colour => (future ? '#ff5588' : '#aa0000'),
          :tip => "#{tip_base} shortfall of #{-overpaid} (#{percentage})" } ]
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
          { "colour": "#003d4a", "text": "outstanding", "font-size": 10 },
          { "colour": "#55aaff", "text": "outstanding (future)", "font-size": 10 },
          { "colour": "#aa0000", "text": "shortfall", "font-size": 10 },
          { "colour": "#00aa00", "text": "overpaid", "font-size": 10 } ] } ],
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
