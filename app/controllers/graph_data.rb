class GraphData < Application
  COLORS = ["edd400", "f57900", "c17d11", "73d216", "3465a4", "75507b", "cc0000", "fce94f", "3465a4", "fcaf3e", "204a87", "ad7fa8", "875678", "456789", "234567"]
  include Grapher
  before :display_from_cache, :exclude => [:today]
  after  :store_to_cache, :exclude => [:today]

  def loan(id)
    @loan      = Loan.get(id)
    raise NotFound unless @loan.disbursal_date
    max_amount = @loan.total_to_be_received
    dates      = @loan.installment_dates
    offset     = 0

    # add dates before the first installment to include the disbursal date
    d = @loan.shift_date_by_installments(dates.min, -1)
    dates  << d

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
      scheduled_outstanding = @loan.scheduled_outstanding_total_on(date).to_i  # or *_principal_on
      actual_outstanding    = future ? scheduled_outstanding : @loan.actual_outstanding_total_on(date).to_i  # or *_principal_on
      overpaid              = scheduled_outstanding - actual_outstanding  # negative means shortfall
      tip_base              = "##{index+1}, #{date}#{(future ? ' (future)' : '')}<br>"
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
    start_date = repository.adapter.query("select MIN(l.scheduled_disbursal_date) start_date FROM loans l, clients cl, centers c, branches b WHERE l.client_id=cl.id AND cl.center_id=c.id AND b.id=c.branch_id AND b.id=#{id.to_i}")[0]
    end_date   = Date.today
    loan_ids   = repository.adapter.query("select l.id start_date FROM loans l, clients cl, centers c, branches b WHERE l.client_id=cl.id AND cl.center_id=c.id AND b.id=c.branch_id AND b.id=#{id.to_i}")
    weekly_aggregate_loan_graph(loan_ids, start_date, end_date)
  end

  def total
    start_date = Loan.all.min(:scheduled_disbursal_date)
    end_date   = Date.today  # (@client.loans.map { |l| l.last_loan_history_date }).max
    loan_ids   = Loan.all(:fields => [:id]).map { |x| x.id }
    weekly_aggregate_loan_graph(loan_ids, start_date, end_date)
  end
  
  def loan_aging
    vals = repository.adapter.query("select count(cl.id) count,cl.date_joined date from clients cl,centers c where cl.center_id=c.id GROUP BY date(cl.date_joined)")
    graph = BarGraph.new("Growth in number of borrowers")
    graph.data(vals.sort_by{|x| x.date})
    graph.x_axis.steps=5
    return graph.generate    
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
      tip_base              = "##{index+1}, #{date}#{(future ? ' (future)' : '')}<br>"
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
      @labels << ((index % step_size == 0) ? date : '')
    end
    render_loan_graph('aggregate loan graph', @stacks, @labels, step_size, max_amount)
  end

  def common_aggregate_loan_graph(loan_ids, start_date, end_date) # __DEPRECATED__
    return "{\"title\":{\"text\": \"No data to display\", \"style\": \"{font-size: 20px;color:##{COLORS[0]}; text-align: center;}\"}}" unless (start_date and end_date)
    days = (end_date - start_date).to_i
    step_size = 1; i = 0   # make a nice round step size, not more than 20 steps
    while days/step_size > 50
      step_size = [1, 7, 14, 30, 60, 365/4, 365/2, 365][i += 1]
    end
    steps = days/step_size + 1
    dates = []
    steps.times { |i| dates << start_date + step_size * i }

    @labels, @stacks, max_amount = [], [], 0
    dates.each_with_index do |date, index|
      t0 =Time.now
      future                = date > Date.today
      s                     = LoanHistory.sum_outstanding_for_loans(date, loan_ids)[0]
      scheduled_outstanding = (s['scheduled_outstanding_total'].to_i or 0)  # or *_principal
      actual_outstanding    = future ? scheduled_outstanding : (s['actual_outstanding_total'].to_i or 0)     # or *_principal
      max_amount            = [max_amount, scheduled_outstanding, actual_outstanding].max
      overpaid              = scheduled_outstanding - actual_outstanding  # negative means shortfall
      tip_base              = "##{index+1}, #{date}#{(future ? ' (future)' : '')}<br>"
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
      @labels << ((index % step_size == 0) ? date : '')
    end
    render_loan_graph('aggregate loan graph', @stacks, @labels, step_size, max_amount)
  end

  def weekly_aggregate_loan_graph(loan_ids, start_date, end_date)
    return "{\"title\":{\"text\": \"No data to display\", \"style\": \"{font-size: 20px; color:#0000ff; text-align: center;}\"}}" unless (start_date and end_date)
    t0 =Time.now
    step_size = 12
    structs = repository.adapter.query(%Q{
      SELECT da_te as date, weeknum,
        SUM(scheduled_outstanding_principal) AS scheduled_outstanding_principal, 
        SUM(scheduled_outstanding_total) AS scheduled_outstanding_total, 
        SUM(actual_outstanding_principal) AS actual_outstanding_principal, 
        SUM(actual_outstanding_total) AS actual_outstanding_total 
        FROM (SELECT da_te, weeknum,
                     scheduled_outstanding_principal,
                     scheduled_outstanding_total, 
                     actual_outstanding_principal, 
                     actual_outstanding_total 
                     FROM (SELECT loan_id, 
                           max(date) as da_te,
                           concat(year(date),'_',week(date)) AS weeknum
                           FROM loan_history 
                           WHERE loan_id IN (#{loan_ids.join(",")})
                           AND status in (5,6)
                           GROUP BY loan_id, weeknum) AS dt,
                           loan_history lh 
                     WHERE lh.loan_id = dt.loan_id 
                     AND lh.date = dt.da_te) AS dt1 GROUP BY weeknum ORDER BY date;})

    @labels, @stacks, max_amount = [], [], 0
    @t = nil
    structs.each_with_index do |s, index|
      # there is a problem with the week that spans two years as it gets spilt into 2008_52 and 2009_0 or similar
      if @t
        s['scheduled_outstanding_total'] += @t['scheduled_outstanding_total']
        s['actual_outstanding_total'] += @t['actual_outstanding_total']
        @t = nil
      end
      if index < structs.size - 1  and structs[index + 1]['weeknum'].index("_0")
        @t = s
        next
      end
      date = s['date']          
      future                = date > Date.today
#      s                     = LoanHistory.sum_outstanding_for(date, loan_ids)[0]
      scheduled_outstanding = (s['scheduled_outstanding_total'].to_i or 0)  # or *_principal
      actual_outstanding    = future ? scheduled_outstanding : (s['actual_outstanding_total'].to_i or 0)     # or *_principal
      max_amount            = [max_amount, scheduled_outstanding, actual_outstanding].max
      overpaid              = scheduled_outstanding - actual_outstanding  # negative means shortfall
      tip_base              = "##{index+1}, #{date}#{(future ? ' (future)' : '')}<br>"
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
      @labels << ((index % step_size == 0) ? date : '')
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
        "labels":       {"rotate": "270", "labels": #{labels.to_json}} },
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

  def dashboard
    labels = []
    case params[:id]
    when "branch_pie"
      vals = repository.adapter.query(%Q{SELECT SUM(l.amount) amount, b.name name
                                         FROM loans l, clients cl, centers c, branches b
                                         WHERE l.client_id=cl.id AND cl.center_id=c.id AND b.id=c.branch_id GROUP BY b.id;})
      graph = PieGraph.new("Branch growth by loan value")
      graph.data(vals, :amount, :name)
      graph.generate
    when "center_day"
      date =  Date.parse(params[:date])
      # restrict branch manager and center managers to their own branches
      centers = ""
      if session.user.role==:staff_member
        st = session.user.staff_member
        center_ids = [st.branches.centers.map{|x| x.id}, st.centers.map{|x| x.id}].flatten.compact
        center_ids = ["NULL"] if center_ids.length==0
        center_ids = "AND center_id in (#{center_ids.join(',')})"
      end
      
      vals = repository.adapter.query(%Q{
                                         SELECT SUM(lh.principal_due), SUM(lh.principal_paid), c.name
                                         FROM loan_history lh, centers c
                                         WHERE lh.center_id = c.id #{center_ids} AND date = '#{date.strftime('%Y-%m-%d')}' GROUP BY lh.center_id})
      
      values = vals.map do |v| 
        val = v[0] + v[1]
        color_ratio = (val == 0 ? 1 : v[0]/val)
        color_ratio = 0 if color_ratio < 0 
        color_value = 65280 + (color_ratio * (16711680 - 65280))
        color = color_value.to_i.to_s(16)
        color = "00" + color if color.length == 4
        {:value => val.to_i, :label => "#{v[2]}( #{v[1].to_i}/ #{(v[1]+v[0]).to_i})", :colour => color}
      end
      type="pie" 
    end
    render_graph(values, type, labels)
  end

  def render_graph(vals, type = "bar", labels = [], steps = 10)
    x = { :elements => [{:type => type, :values => vals}]}
    x_axis = {:labels => {:labels => labels.to_json, :steps => steps}}
    x[:x_axis] = x_axis
    return x.to_json
  end

  private
  def display_from_cache
    return false if params[:action]=="dashboard" and params[:id]=="center_day"
    file = get_cached_filename
    return true unless File.exists?(file)
    return true if not File.mtime(file).to_date==Date.today
    throw :halt, render(File.read(file), :layout => false)
  end
  
  def store_to_cache
    return false if params[:action]=="dashboard" and params[:id]=="center_day"
    file = get_cached_filename
    if not (File.exists?(file) and File.mtime(file).to_date==Date.today)
      File.open(file, "w"){|f|
        f.puts @body
      }
    end
  end
  
  def get_cached_filename
    hash = params.deep_clone
    dir = File.join(Merb.root, "public", hash.delete(:controller).to_s, hash.delete(:action).to_s, hash.delete(:id).to_s)
    unless File.exists?(dir)
      FileUtils.mkdir_p(dir)
    end
    File.join(dir, hash.collect{|k,v| "#{k}_#{v}"})
  end
  
  def get_steps(max)
    divisor = power(max)
    (max/(10**divisor)).to_i*10*divisor
  end
  
  def power(val, base=10)
    itr=1
    while val/(base**itr) > 1
      itr+=1
    end
    return itr-1
  end
end
