class Dashboard < Application
  include Grapher
  before :display_from_cache, :exclude => [:index]
  after  :store_to_cache, :exclude => [:index]

  def index
    render
  end

  def today
    @date = params[:date].blank? ? Date.today : Date.parse(params[:date])
    render
  end

  def branch
    case params[:id]
    when nil
      if params[:group_by]=="client"
        graph = PieGraph.new("Branch status by #{params[:group_by]} count")
        vals = repository.adapter.query(%Q{SELECT COUNT(cl.id) count, b.name name
                                       FROM clients cl, centers c, branches b
                                       WHERE cl.center_id=c.id AND b.id=c.branch_id GROUP BY b.id;})
        graph.data(vals, [:count, :to_i], :name)
      elsif params[:group_by]=="loan"
        graph = PieGraph.new("Branch status by #{params[:group_by]} amount")
        vals = repository.adapter.query(%Q{SELECT SUM(l.amount) amount, b.name name
                                       FROM loans l, clients cl, centers c, branches b
                                       WHERE l.client_id=cl.id AND cl.center_id=c.id AND b.id=c.branch_id GROUP BY b.id;})
        graph.data(vals, [:amount, :to_i], :name)
      end
      return graph.generate
    else
      branch    = Branch.get(params[:id])
      graph = BarGraph.new("Client growth at #{branch.name}")
      vals  = repository.adapter.query(%Q{SELECT count(cl.id) count, cl.date_joined date 
                                          FROM clients cl, centers c 
                                          WHERE c.branch_id=#{branch.id} and cl.center_id=c.id group by date(cl.date_joined)}).sort_by{|x| x.date}
      graph.data(vals)
      graph.x_axis.steps=5
      return graph.generate
    end
  end

  def centers
    if params[:id]
      @branch =  Branch.get(params[:id])
      graph = BarGraph.new("Growth of number of clients in centers of #{@branch.name}")
      vals  = Center.all(:branch => @branch).aggregate(:all.count, :created_at)
    else
      graph = BarGraph.new("Growth of number of clients in centers")
      vals  = Center.all.aggregate(:all.count, :created_at)
    end
    graph.data(vals.map{|x| [x.first, x.last.strftime("%d-%b")]}, :first, :last)
    graph.x_axis.steps=2
    return graph.generate
  end

  def loans
    case params[:id]
    when "borrowers"
      vals = repository.adapter.query("select count(cl.id) count,cl.date_joined date from clients cl,centers c where cl.center_id=c.id GROUP BY date(cl.date_joined)")
      graph = BarGraph.new("Growth in number of borrowers")
      graph.data(vals.sort_by{|x| x.date})
      graph.x_axis.steps=5
      return graph.generate
    when "breakup"
      graph  = PieGraph.new("Loan #{params[:by]} breakup")
      data   = group_by_values(Loan, Loan.all, :occupation, {:allow_blank => true})
      avg    = data.collect{|x| x[0]}.reduce{|s,x| s+=x}.to_f/(data.length)
      graph.data(data, :first, :last)
      return graph.generate
    when "aging"
      ages = {1 => 0, 2 => 0, 3 => 0, 4  => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0}
      Loan.all(:disbursal_date.not => nil, :disbursal_date.lte => Date.today).each{|l|
        ages[(100*(Date.today-l.disbursal_date)/(l.number_of_installments * l.installment_frequency_in_days)/10).ceil]+=1
      }
      vals = []
      ages.to_a.sort_by{|x| x[0]}.each{|key, count|
        vals.push([count, "#{(key-1)*10} to #{key*10} %"])
      }      
      graph = BarGraph.new("Aging analysis")
      graph.data_type=:individual
      graph.data(vals)
      return graph.generate      
    end
  end

  def clients
    case params[:id]
    when "growth"
      dater =  Proc.new{|x| x.strftime('%Y-%m')}
      vals  = get_clients.aggregate(:all.count, :fields => [:date_joined]).group_by_function(dater)
      graph = BarGraph.new("Client growth per month")
      graph.data_type=:individual
      graph.data(vals, :last, :first)
      return graph.generate
    when "cumulative"
      vals = get_clients.aggregate(:all.count, :date_joined).map{|x| [x.first, x.last.strftime("%b %y")]}
      graph = BarGraph.new("Client cumulative growth")
      graph.data(vals, :first, :last)
      graph.x_axis.steps=10
      return graph.generate
    when "breakup"
      graph  = PieGraph.new("Client #{params[:by]} breakup")
      group_by = params[:group_by].to_sym
      graph.data(group_by_values(Client, get_clients, group_by, {:allow_blank => false}), :first, :last)
      return graph.generate
    end    
  end

  private
  def group_by_values(model, collection, group_by, opts = {})
    opts[:allow_blank]=false if not opts.key?(:allow_blank)
    property = model.properties.find{|x| x.name==group_by} 

    if property and property.type.class==Class
      lookup = property.type.flag_map
    elsif property
      lookup = false
    elsif model.relationships.key?(group_by)
      lookup = {}
      model.relationships[group_by].parent_model.all.each{|x| lookup[x.id]=x.name}
      group_by = model.relationships[group_by].child_key.first.name
    end

    if lookup
      lookup[""]  = lookup[nil] = "Not specified" if opts[:allow_blank]
      return collection.aggregate(:all.count, group_by).map{|c|
        id = c[1].to_i
        [c[0], lookup[id]]
      }.reject{|x| x[1].nil? or x[1].blank?}
    else
      if opts[:allow_blank]
        return collection.aggregate(:all.count, group_by)
      else
        return collection.aggregate(:all.count, group_by).reject{|x| x.nil? or x.blank?}
      end
    end
  end

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
    controller = hash.delete(:controller).to_s
    action     = hash.delete(:action).to_s
    [:format, :submit].each{|x| hash.delete(x)}
    dir = File.join(Merb.root, "public", controller, action)
    unless File.exists?(dir)
      FileUtils.mkdir_p(dir)
    end
    File.join(dir, hash.collect{|k,v| "#{k}_#{v}"}.join("_"))
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

  def get_clients
    hash = {}
    [:branch_id, :center_id, :staff_member_id].each{|attr| hash[attr] = params[attr] if params[attr] and not params[attr].blank?}
    if hash.empty?
      return Client.all
    else
      if hash[:center_id]
        hash.delete(:branch_id)
        return Client.all(hash)
      elsif hash[:staff_member_id]
        return StaffMember.get(hash[:staff_member_id]).clients
      elsif hash[:branch_id]
        return Center.all(hash).clients(:fields => [:id, :date_joined, :religion, :caste])
      end
    end
  end
end


