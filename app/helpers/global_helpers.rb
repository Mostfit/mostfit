module Merb
  module GlobalHelpers
    CRUD_ACTIONS = ["list", "index", "show", "edit", "new"]
    MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
    TRANSACTION_MODELS = [Branch, Center, ClientGroup, Cgt, Grt, Client, Loan, Payment]
    
    def page_title
      begin
        generate_page_title(params)
      rescue
        return "MostFit" rescue Exception
      end
    end

    def link_to_with_class(name, url)
      link_to_with_rights(name, url, :class => ((request.uri==(url) or request.uri.index(url)==0) ? "selected" : ""))
    end

    def link_to_with_rights(text, path, params = {}, method="GET")
      uri = URI.parse(path)
      method = method.to_s.upcase || "GET"
      request = Merb::Request.new(
                                  Merb::Const::REQUEST_PATH => uri.path,
                                  Merb::Const::REQUEST_METHOD => method,
                                  Merb::Const::QUERY_STRING => uri.query)
      route = Merb::Router.match(request)[1] rescue nil
      return link_to(text,path,params) if session.user.can_access?(route, params)
    end

    def url_for_loan(loan, action = '', opts = {})
      # this is to generate links to loans, as the resouce method doesn't work for descendant classes of Loan
      # it expects the whole context (@branch, @center, @client) to exist
      base = if @branch and @center and @client
               url(:branch_center_client, @branch.id, @center.id, @client.id)
             elsif @client
               url(:branch_center_client, @client.center.branch_id, @client.center_id, @client.id)
             else
               client = loan.client
               url(:branch_center_client, client.center.branch_id, client.center_id, client.id)
             end
      base + "/loans/#{loan.id}/" + action.to_s + (opts.length>0 ? "?#{opts.inject([]){|s,x| s << "#{x[0]}=#{x[1]}"}.join("&")}" : '')
    end

    def select_staff_member_for(obj, col, attrs = {}, allow_unassigned=false)
      id_col = "#{col.to_s}_staff_id".to_sym
      selected = ((obj.send(id_col) and obj.send(id_col)!="") ? obj.send(id_col).to_s : attrs[:selected] || "0")
      allow_inactive = false

      if selected and selected.to_i>0
        staff = StaffMember.get(selected)
        allow_inactive = true unless staff.active
      end
      
      select(col,
             :collection   => staff_members_collection(allow_unassigned, allow_inactive),
             :name         => "#{obj.class.to_s.snake_case}[#{id_col}]",
             :id           => attrs[:id] || "#{obj.class.to_s.snake_case}_#{id_col}",
             :selected     => selected)
    end

    def select_center_for(obj, col, attrs = {})
      id_col = "#{col.to_s}_id".to_sym
      collection = []
      catalog = Center.catalog(session.user)
      catalog.keys.sort.each do |branch_name|
        collection << ['', branch_name]
        catalog[branch_name].sort_by{|x| x[1]}.each{ |k,v| collection << [k.to_s, "!!!!!!!!!#{v}"] }
      end
      html = select col,
        :collection   => collection,
        :name         => "#{obj.class.to_s.snake_case}[#{id_col}]",
        :id           => "#{obj.class.to_s.snake_case}_#{id_col}",
        :selected     => (obj.send(id_col) ? obj.send(id_col).to_s : nil),
        :prompt       => (attrs[:prompt] or "&lt;select a center&gt;")
      html.gsub('!!!', '&nbsp;')  # otherwise the &nbsp; entities get escaped
    end

    def select_funding_line_for(obj, col, attrs = {}) # Fix me: Refactor this with all select_*_for
      id_col = "#{col.to_s}_id".to_sym
      catalog = Funder.catalog
      collection = []
      catalog.keys.sort.each do |funder_name|
        collection << ['', funder_name]
        catalog[funder_name].each_pair { |k,v| collection << [k.to_s, "!!!!!!#{v}"]}
      end
      html = select col,
        :collection   => collection,
        :name         => "#{obj.class.to_s.snake_case}[#{id_col}]",
        :id           => "#{obj.class.to_s.snake_case}_#{id_col}",
        :selected     => (obj.send(id_col) ? obj.send(id_col).to_s : nil),
        :prompt       => (attrs[:prompt] or "&lt;select a funding line&gt;")
      html.gsub('!!!', '&nbsp;')  # otherwise the &nbsp; entities get escaped
    end

    def date_select(name, date = Date.today, opts={})
      # defaults to Date.today
      # should refactor
      attrs = {}
      attrs.merge!(:name => name)
      attrs.merge!(:date => date)
      attrs.merge!(:id => opts[:id]||name)
      attrs.merge!(:date     => date)
      attrs.merge!(:size     => opts[:size]||20)
      attrs.merge!(:min_date => opts[:min_date]||Date.min_date)
      attrs.merge!(:max_date => opts[:max_date]||Date.max_date)
      attrs.merge!(:nullable => opts[:nullable]) if opts.key?(:nullable)
      date_select_html(attrs) 
    end
 
    def date_select_for(obj, col = nil, attrs = {})
      klass = obj.class
      attrs.merge!(:name => "#{klass.to_s.snake_case}[#{col.to_s}]")
      attrs.merge!(:id   => "#{klass.to_s.snake_case}_#{col.to_s}")
      attrs[:nullable]   = (attrs.key?(:nullable) ? attrs[:nullable] : Mfi.first.date_box_editable)
      date = attrs[:date] || obj.send(col)
      date = Date.today if date.blank? and not attrs[:nullable]
      date = nil        if date.blank? and attrs[:nullable]
      attrs.merge!(:date => date)
      if TRANSACTION_MODELS.include?(klass) or TRANSACTION_MODELS.include?(klass.superclass) or TRANSACTION_MODELS.include?(klass.superclass.superclass)
        attrs.merge!(:min_date => attrs[:min_date]||Date.min_transaction_date)
        attrs.merge!(:max_date => attrs[:max_date]||Date.max_transaction_date)
      else
        attrs.merge!(:min_date => attrs[:min_date]||Date.min_date)
        attrs.merge!(:max_date => attrs[:max_date]||Date.max_date)
      end
      date_select_html(attrs, obj, col)
#       errorify_field(attrs, col)
    end

    def date_select_html (attrs, obj = nil, col = nil)      
      str = %Q{
        <input type='text' name="#{attrs[:name]}" id="#{attrs[:id]}" value="#{attrs[:date]}" size="#{attrs[:size]}" #{attrs[:nullable] ? "" : "readonly='true'"}>
        <script type="text/javascript">
          $(function(){
            $("##{attrs[:id]}").datepicker('destroy').datepicker({altField: '##{attrs[:id]}', buttonImage: "/images/calendar.png", changeYear: true, buttonImageOnly: true,
                                            yearRange: '#{attrs[:min_date].year}:#{attrs[:max_date].year}',
                                            dateFormat: '#{datepicker_dateformat}', altFormat: '#{datepicker_dateformat}', minDate: '#{attrs[:min_date]}',
                                            maxDate: '#{attrs[:max_date]}', showOn: 'both', setDate: "#{attrs[:date]}" })
          });

       </script>
      }
      return str
    end

    def datepicker_dateformat
      if Mfi.first and not Mfi.first.date_format.blank?
        ourDateFormat = Mfi.first.date_format
      else
        ourDateFormat = "%Y-%m-%d"
      end
      s = ourDateFormat.dup
      s.gsub!("%Y","yy")
      s.gsub!("%y","y")
      s.gsub!("%m","mm")
      s.gsub!("%d","dd")
      s.gsub!("%B","MM")
      s.gsub!("%A","DD")
      return s
    end

    #old func it shows textbox
    def date_select_old_html (attrs, obj = nil, col = nil)
      date = attrs[:date]
      nullable = attrs[:nullable]
      day_attrs = attrs.merge(
        :name       => attrs[:name] + '[day]',
        :id         => attrs[:id] + '_day',
        :selected   => (date ? date.day.to_s : ''),
        :class      => (obj and col) ? (obj.errors[col] ? 'error' : '') : nil,
        :collection =>  (nullable ? [['', '-']] : []) + (1..31).to_a.map{ |x| x = [x.to_s, x.to_s] }
      )
      
      count = 0
      month_attrs = attrs.merge(
        :name       => attrs[:name] + '[month]',
        :id         => attrs[:id] + '_month',
        :selected   => (date ? date.month.to_s : ''),
        :class      => obj ? (obj.errors[col] ? 'error' : '') : nil,
        :collection => (nullable ? [['', '-']] : []) + MONTHS.map { |x| count += 1; x = [count, x] }
      )

      min_year = attrs[:min_date] ? attrs[:min_date].year : 1900
      max_year = attrs[:max_date] ? attrs[:max_date].year : date.year + 3
      year_attrs = attrs.merge(
        :name       => attrs[:name] + '[year]',
        :id         => attrs[:id] + '_year',
        :selected   => (date ? date.year.to_s : ''),
        :class      => obj ? (obj.errors[col] ? 'error' : '') : nil,
        :collection => (nullable ? [['', '-']] : []) + (min_year..max_year).to_a.reverse.map{|x| x = [x.to_s, x.to_s]}
      )
      select(month_attrs) + '' + select(day_attrs) + '' + select(year_attrs)
    end


    def ofc2(width, height, url, id = Time.now.usec, swf_base = '/')
      <<-HTML
        <div id='flashcontent_#{id}'></div>
        <script type="text/javascript">
          swfobject.embedSWF(
            "#{swf_base}open-flash-chart.swf", "flashcontent_#{id}",
            "#{width}", "#{height}", "9.0.0", "expressInstall.swf",
            {"data-file":"#{url}", "loading":"Waiting for data... (reload page when it takes too long)"}, {"wmode": "transparent"} );
        </script>
      HTML
    end

    def breadcrums
      # breadcrums use the request.uri and the instance vars of the parent
      # resources (@branch, @center) that are available -- so no db queries
      crums, url = [], ''
      request.uri.split("?")[0][1..-1].split('/').each_with_index do |part, index|
        url  << '/' + part
        if part.to_i.to_s.length == part.length  # true when a number (id)
          o = instance_variable_get('@'+url.split('/')[-2].singular)  # get the object (@branch)
          s = (o.respond_to?(:name) ? link_to(o.name, url) : link_to('#'+o.object_id.to_s, url))
          crums[-1] += ": <b><i>#{s}</i></b>"  # merge the instance names (or numbers)
        else  # when not a number (id)
          crums << link_to(part.gsub('_', ' '), url)  # add the resource name
        end
      end
      ['You are here', crums].join('&nbsp;<b>&gt;&gt;</b>&nbsp;')  # fancy separator
    end

    def format_currency(i)
      # in case of our rupees we do not count with cents, if you want to have cents do that here
      i.to_f.round(2).to_s + " INR"
    end

    def plurial_nouns(freq)
      case freq.to_sym
        when :daily
          'days'
        when :weekly
          'weeks'
        when :monthly
          'months'
        else
          '????'
      end
    end

    def difference_in_days(start_date, end_date, words = ['days early', 'days late'])
      d = end_date - start_date
      return '' if d == 0
      "#{d.abs} #{d > 0 ? words[1] : words[0]}"
    end

    def debug_info
      [
        {:name => 'merb_config', :code => 'Merb::Config.to_hash', :obj => Merb::Config.to_hash},
        {:name => 'params', :code => 'params.to_hash', :obj => params.to_hash},
        {:name => 'session', :code => 'session.to_hash', :obj => session.to_hash},
        {:name => 'cookies', :code => 'cookies', :obj => cookies},
        {:name => 'request', :code => 'request', :obj => request},
        {:name => 'exceptions', :code => 'request.exceptions', :obj => request.exceptions},
        {:name => 'env', :code => 'request.env', :obj => request.env},
        {:name => 'routes', :code => 'Merb::Router.routes', :obj => Merb::Router.routes},
        {:name => 'named_routes', :code => 'Merb::Router.named_routes', :obj => Merb::Router.named_routes},
        {:name => 'resource_routes', :code => 'Merb::Router.resource_routes', :obj => Merb::Router.resource_routes},
      ]
    end

    def paginate(pagination, *args, &block)
      DmPagination::PaginationBuilder.new(self, pagination, *args, &block)
    end

    def paginate_array(arr, params, length)
      page = ((params[:page] and not params[:page].blank?) ? params[:page].to_i : 1)
      str  = ""
      if page <= 1
        page = 1
      else
        params[:page] = page - 1
        str += link_to("prev", url(params))
      end

      params[:page] = page + 1

      if (length / 20.0).ceil <= page
        str
      else
        str + " | " + link_to("next", url(params))
      end
    end

    def chart(url, width=430, height=200, id=nil)
      id||= (rand()*100000).to_i + 100
      "<div id='flashcontent_#{id}'></div>
      <script type='text/javascript'> 
      swfobject.embedSWF('/open-flash-chart.swf', \"flashcontent_#{id}\", #{width}, #{height}, '9.0.0', 'expressInstall.swf',
                         {\"data-file\": \"#{url}\",
                          \"loading\": \"Waiting for data... (reload page when it takes too long)\"
                         });
     </script>"
    end

    def centers_paying_today_collection(date)
      [["","---"]] + Center.paying_today(session.user, date).map {|c| [c.id.to_s,c.name]}
    end
    
    def audit_trail_url
      "/audit_trails?"+params.to_a.map{|x| "audit_for[#{x[0]}]=#{x[1]}"}.join("&")
    end

    def diff_display(arr, obj, action)      
      relations = {}
      if obj.class == String
        model = Kernel.const_get(obj)
      else
        model = obj.class
        return unless obj
        relations = model.relationships.find_all{|k, v|
          v.class ==  DataMapper::Associations::ManyToOne::Relationship
        }.map{|k,v| {v.child_key.first.name => [k, v.parent_key.first.model]}}.reduce({}){|s,x| s+=x}
      end

      arr.map{|change|
        next unless change
        change.map{|k, v|
          if relations.key?(k)
            str = "<tr><td>#{relations[k].first.to_s.humanize}</td><td>"
            str += (if action==:update and v.class==Array
                      str = "changed from "
                      if v.first and relations[k] and obj=relations[k].last.get(v.first)
                        str += obj.name
                      else
                        str += "nil"
                      end
                      str += "</td><td>to "

                      if v.last and relations[k] and obj=relations[k].last.get(v.last)
                        str += obj.name
                      else
                        str += "nil"
                      end
                      str
                    elsif action==:create and v.class==Array
                      child_obj = relations[k].last.get(v.last)
                      ((child_obj and child_obj.respond_to?(:name)) ? child_obj.name : "id: #{v.last}")
                    elsif action==:create
                      child_obj = relations[k].last.get(v)
                      ((child_obj and child_obj.respond_to?(:name)) ? child_obj.name : "id: #{v.last}")
                    else
                      "#{v}"
                    end)||""
          else
            str="<tr><td>#{k.humanize}</td><td>"
            str+=if action==:update and v.class==Array
                   if model.properties.find{|x| x.name == k}.type.respond_to?(:flag_map)
                     "changed from #{model.properties.find{|x| x.name == k}.type.flag_map[v.first]}</td><td>to #{v.last}"                     
                   else
                     "changed from #{v.first}</td><td>to #{v.last}"
                   end
                 elsif action==:create and v.class==Array
                   "#{v}"
                 else
                   "#{v}"
                 end
          end
          str+="</td></tr>"
        }
      }
    end

    def search_url(hash, model)
      hash[:controller] = "search"
      hash[:action]     = "advanced"
      hash[:model]      = model.to_s.downcase
      hash              = hash.map{|x| 
        [(x[0].class==DataMapper::Query::Operator ? "#{x[0].target}.#{x[0].operator}" : x[0]), x[1]]
      }.to_hash
      url(hash)
    end

    def use_tinymce
      @content_for_tinymce = "" 
      content_for :tinymce do
        js_include_tag "tiny_mce/tiny_mce"
      end
      @content_for_tinymce_init = "" 
      content_for :tinymce_init do
        js_include_tag "mce_editor"
      end
    end

    def get_accessible_areas(staff)
      if staff or staff = session.user.staff_member
        [staff.branches.areas, staff.areas].flatten
      else
        Area.all(:order => [:name])
      end
    end

    def get_accessible_branches(staff=nil)
      if staff or staff=session.user.staff_member
        [staff.centers.branches, staff.branches, staff.areas.branches, staff.regions.areas.branches].flatten
      else
        Branch.all(:order => [:name])
      end
    end
    
    def get_accessible_centers(branch_id, staff=nil)
      centers = if staff or session.user.staff_member
                  Center.all(:branch => get_accessible_branches, :order => [:name])
                elsif branch_id and not branch_id.blank?
                  Center.all(:branch_id => branch_id, :order => [:name])
                else 
                  []
                end      
      centers.map{|x| [x.id, "#{x.name}"]}
    end

    def get_accessible_staff_members(staff=nil)
      staff_members   =  if staff or staff = session.user.staff_member
                           if branches = staff.branches and branches.length>0
                             [staff] + branches.centers.managers(:order => [:name])
                           elsif centers = staff.centers and centers.length>0
                             [staff] + centers.managers(:order => [:name])
                           else
                             [staff] + [staff]
                           end
                         else
                           StaffMember.all(:order => [:name])
                         end      
      staff_members.map{|x| [x.id, x.name]}
    end

    def get_accessible_funders(user=nil)
      (if user.role == :funder
        Funder.all(:user => user)
      else
        Funder.all
      end).map{|x| [x.id, "#{x.name}"]}
    end
    
    def get_accessible_accounts
      Account.all(:order => [:name])
    end
    def select_mass_entry_field(attrs)
      collection = []
      MASS_ENTRY_FIELDS.keys.each do |model|
        collection << ['', model.to_s.camelcase(' ')]
        MASS_ENTRY_FIELDS[model].sort_by{|x| x.to_s}.each{|k| collection << ["#{model}[#{k.to_s}]", "!!!!!!#{k.to_s.camelcase(' ')}"] }
      end
      select(
             :collection   => collection,
             :name         => "#{attrs[:name]}",
             :id           => "#{attrs[:id]||'select_mass_entry'}",
             :prompt       => (attrs[:prompt] or "&lt;select a field&gt;")).gsub("!!!", "&nbsp;")
    end

    def paginate_on_weekdays(branch, selected=Date.today.weekday)      
      Center::DAYS.map{|wday|
        weekday = (wday==:none ? "Not defined" : wday.to_s)
        if selected==wday
          "<strong>#{weekday}</strong>"
        else
          link_to(weekday, url(:controller => "centers", :action => "list", :branch_id => branch, :meeting_day => wday.to_s), :id => "centers_list", :class => "_remote_")
        end
      }.join(' | ')
    end

    def select_accounts(name, branch=nil, attrs = {})
      collection = []
      Account.all(:branch => branch).group_by{|a| a.account_type}.sort_by{|at, as| at.name}.each do |account_type, accounts|
        collection << ['', "#{account_type.name}"]
        accounts.sort_by{|a| a.name}.each{|a| collection << [a.id.to_s, "!!!!!!!!!#{a.name}"] }
      end
      html = select(
        :collection   => collection,
        :name         => name,
        :id           => attrs[:id],
        :selected     => attrs[:selected],
        :prompt       => (attrs[:prompt] or "&lt;select a account&gt;"))
      html.gsub('!!!', '&nbsp;')  # otherwise the &nbsp; entities get escaped
    end
    
    def approx_address(obj)
      if obj.class == Center
        str  =  obj.name
        str += obj.branch.name      if obj.branch and not obj.name.include?(obj.branch.name)
        str += obj.branch.area.name if obj.branch.area
        return str
      elsif obj.respond_to?(:address) and not obj.address.blank?
        obj.address
      elsif obj.class == Branch
        obj.address.blank? ? obj.name : obj.address
      end
    end

    private
    def staff_members_collection(allow_unassigned=false, allow_inactive=false)
      hash = allow_inactive ? {} : {:active => true}
      if staff = session.user.staff_member
        bms  = staff.branches.collect{|x| x.manager}
        cms  = staff.branches.centers.collect{|x| x.manager}               
        managers = [bms, cms, staff].flatten.uniq
        managers+= (StaffMember.all(hash.merge(:order => [:name])) - Branch.all.managers - Center.all.managers - Region.all.managers - Area.all.managers) if allow_unassigned
        [["0", "<Select a staff member"]] + managers.map{|x| [x.id, x.name]}
      else
        [["0", "<Select a staff member"]] + StaffMember.all(hash.merge(:order => [:name])).map{|x| [x.id, x.name]}
      end
    end
    
    def join_segments(*args)
      args.map{|x| x.class==Array ? x.uniq : x}.flatten.reject{|x| not x or x.blank?}.join(' - ').capitalize
    end

    def generate_page_title(params)
      prefix, postfix = [], []
      controller=params[:controller].split("/")[-1]
      controller_name = (params[:action]=="list" or params[:action]=="index") ? controller.join_snake(' ') : controller.singularize.join_snake(' ')
      controller_name = controller_name.map{|x| x.join_snake(' ')}.join(' ')
      prefix  << params[:namespace].join_snake(' ') if params[:namespace]
      postfix << params[:action].join_snake(' ') if not CRUD_ACTIONS.include?(params[:action])
      prefix  << params[:action].join_snake(' ') if CRUD_ACTIONS[3..-1].include?(params[:action])
      
      return "Loan for #{@loan.client.name}" if controller=="payments" and @loan
      return params[:report_type] if controller=="reports" and params[:report_type]

      #Check if @<controller> is available
      unless instance_variables.include?("@"+controller.singularize)
        return join_segments(prefix, controller_name, postfix)
      end

      #if @<controller> is indeed present
      obj = instance_variable_get("@"+controller.singularize)
#      prefix  += "New" if obj.new?
      postfix << "for #{@loan.client.name}" if obj.respond_to?(:client)

      return join_segments(prefix, controller_name, obj.name, postfix) if obj.respond_to?(:name) and not obj.new?
      #catch all
      return join_segments(prefix, controller_name, postfix)
    end    

    def self.pretty_name_of_comparator(comparator)
      if comparator == "less_than" then return "<"
      elsif comparator == "less_than_equal" then return "<="
      elsif comparator == "greater_than" then return ">"
      elsif comparator == "greater_than_equal" then return ">="
      elsif comparator == "equal" then return "="
      elsif comparator == "equal1" then return "="
      elsif comparator == "equal2" then return "="
      elsif comparator == "not" then return "!="
      elsif comparator == "not1" then return "!="
      elsif comparator == "not2" then return "!="
      else return comparator
      end
    end

    def getPages(current_page, minimum=1, maximum=20, window=2)
      return((minimum + window < current_page ? minimum.upto(window).collect : minimum.upto(current_page + window).collect) + (current_page - window > minimum+window ? [".."] : []) + (current_page > minimum + window ? (current_page - window > minimum + window ? current_page - window : minimum + window).upto(current_page + window > maximum ? maximum : current_page + window).collect : []) + (current_page + window + 1 < maximum - window ? [".."] : []) + (current_page < maximum - 2 * window ? maximum-window : current_page + window + 1).upto(maximum).collect)
    end

    # get the loans which are accessible by the user
    def get_loans(hash)
      if staff = session.user.staff_member
        hash["client.center.branch_id"] = [staff.branches, staff.areas.branches, staff.regions.areas.branches].flatten.map{|x| x.id}
      end
      Loan.all(hash)
    end
  end
end
