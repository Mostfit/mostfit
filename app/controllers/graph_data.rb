class GraphData < Application

  def loan(id)
    @loan = Loan.get(id)
    max_amount = @loan.total_to_be_received
    structs = LoanHistory.raw_structs_for_loan(id, @loan.installment_dates)

    step_size = 1; i = 0   # make a nice round step size, not more than 20 steps
    while structs.size/step_size > 20
      step_size = [1, 5, 10, 20, 50, 100, 200, 500, 1000][i += 1]
    end

    @labels, @stacks = [], []
    structs.each_with_index do |s, index|
      date                 = Date.parse(s['date'])
      schduled_outstanding = s['scheduled_outstanding_total']  # or *_principal
      actual_outstanding   = s['actual_outstanding_total']     # or *_principal
      overpaid             = schduled_outstanding - actual_outstanding  # negative means shortfall
      tip_base             = "##{index+1}, #{date.strftime("%a %b %d %Y")}<br>"
      percentage           = (overpaid.abs.to_f/max_amount).round.to_s + '%'
      future               = date > Date.today
      @stacks << [
        { :val => [schduled_outstanding, actual_outstanding].min, :colour => (future ? '#55aaff' : '#003d4a'),
          :tip => tip_base + (future ? ' (future)' : '') },
        { :val => [overpaid,  0].max, :colour => (future ? '#55ff55' : '#00aa00'),
          :tip => "#{tip_base}\n#{ overpaid} (#{percentage}) overpaid#{future ? ' (future)' : ''}" },
        { :val => [-overpaid, 0].max, :colour => (future ? '#ff5588' : '#aa0000'),
          :tip => "#{tip_base}\n#{-overpaid} (#{percentage}) shortfall#{future ? ' (future)' : ''}" } ]
      @labels << ((index % step_size == 0) ? (index+1).to_s : '')
    end

    <<-JSON
    { "elements": [ { 
        "type": "bar_stack", 
        "colours": [ "#666666", "#00aa00", "#aa0000" ], 
        "values": #{@stacks.to_json}, 
        "keys": [ 
          { "colour": "#aa0000", "text": "shortfall", "font-size": 10 },
          { "colour": "#ff5588", "text": "shortfall (future)", "font-size": 10 },
          { "colour": "#00aa00", "text": "overpaid", "font-size": 10 },
          { "colour": "#55ff55", "text": "overpaid (future)", "font-size": 10 } ] } ],
      "x_axis": {
        "steps":        #{step_size},
        "colour":       "#333333",
        "grid-colour":  "#ffffff",
        "labels":       { "labels": #{@labels.to_json}} },
      "x_legend":       { "text": "installments", "style": "{font-size: 11px; color: #003d4a; font-weight: bold;}" },
      "y_axis": {
        "colour":       "#333333",
        "grid-colour":  "#bc6624",
        "steps":        #{max_amount/8},
        "min":          0,
        "max":          #{max_amount} },
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


  def client(id)
    @client = Client.get(id)
#     return loan(@client.loans.first.id) if @client.loans.size == 1  # nicely prints on the installment dates

    first_date = @client.loans.min(:approved_on)
    last_date = (@client.loans.map { |l| l.last_loan_history_date }).max
    days = (last_date - first_date).to_i

    step_size = 1; i = 0   # make a nice round step size, not more than 20 steps
    while days/step_size > 20
      step_size = [1, 7, 14, 30, 60, 365/4, 365/2, 365][i += 1]
    end
    steps = days/step_size + 1
    dates = []
    steps.times { |i| dates << first_date + step_size * i }
p [dates.to_json, step_size]
    t = @client.loans.history.sum(:total_scheduled, :conditions => ['date > ? AND date < ?', first_date, last_date])
    h = @client.loans.history(:order => [:date], :conditions => ['date IN ?', dates])
p t
p '@@@@@@@@@@@@@@@@@@@@@@22'
    @labels, @stacks = [], []
    h.each_with_index do |r, index|
      schduled_outstanding = t - r.total_scheduled
      actual_outstanding   = t - r.total_received
      diff = schduled_outstanding - actual_outstanding  # positive diff means overpaid (neg. means shortfall)
      tip_base = "##{index+1}, #{r.date.strftime("%a %b %d %Y")}<br>"
      future = r.date > Date.today
      @stacks << [
        { :val => [schduled_outstanding, actual_outstanding].min, :colour => (future ? "#55939f" : "#003d4a"),
          :tip => tip_base + (future ? ' (future)' : '') },
        { :val => [diff,  0].max, :colour => (future ? '#55ff55' : '#00aa00'),
          :tip => "#{tip_base}\n#{diff} overpaid#{future ? ' (future)' : ''}" },
        { :val => [-diff, 0].max, :colour => (future ? '#ff5555' : '#aa0000'),
          :tip => "#{tip_base}\n#{-diff} shortfall#{future ? ' (future)' : ''}" } ]
      @labels << ((index % step_size == 0) ? (index+1).to_s : '')
    end

    <<-JSON
    { "elements": [ { 
        "type": "bar_stack", 
        "colours": [ "#666666", "#00aa00", "#aa0000" ], 
        "values": #{@stacks.to_json}, 
        "keys": [ 
          { "colour": "#aa0000", "text": "shortfall", "font-size": 10 },
          { "colour": "#ff5555", "text": "shortfall (future)", "font-size": 10 },
          { "colour": "#00aa00", "text": "overpaid", "font-size": 10 },
          { "colour": "#55ff55", "text": "overpaid (future)", "font-size": 10 } ] } ],
      "x_axis": {
        "steps":        #{step_size},
        "colour":       "#333333",
        "grid-colour":  "#ffffff",
        "labels":       { "labels": #{@labels.to_json}} },
      "x_legend":       { "text": "time in days", "style": "{font-size: 11px; color: #003d4a; font-weight: bold;}" },
      "y_axis": {
        "colour":       "#333333",
        "grid-colour":  "#bc6624",
        "steps":        #{t/8},
        "min":          0,
        "max":          #{t} },
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
