module Merb
  module GlobalHelpers
    def url_for_loan(loan, action = '')
      # this is to generate links to loans, as the resouce method doesn't work for descendant classes of Loan
      # it expects the whole context (@branch, @center, @client) to exist
      base = url(:branch_center_client, @branch.id, @center.id, @client.id)
      base + "/loans/#{loan.id}/" + action
    end

    def select_staff_member_for(obj, col, attrs = {})
      id_col = "#{col.to_s}_staff_id".to_sym
      select col,
        :collection   => StaffMember.all(:active => true),
        :value_method => :id,
        :text_method  => :name,
        :name         => "#{obj.class.to_s.snake_case}[#{id_col}]",
        :id           => "#{obj.class.to_s.snake_case}_#{id_col}",
        :selected     => (obj.send(id_col) ? obj.send(id_col).to_s : nil),
        :prompt       => (attrs[:prompt] or "&lt;select a staff member&gt;")
    end

    def select_center_for(obj, col, attrs = {})
      id_col = "#{col.to_s}_id".to_sym
      collection = []
      catalog = Center.catalog
      catalog.keys.sort.each do |branch_name|
        collection << ['', branch_name]
        catalog[branch_name].each_pair { |k,v| collection << [k.to_s, "!!!!!!!!!#{v}"] }
      end
      html = select col,
        :collection   => collection,
        :name         => "#{obj.class.to_s.snake_case}[#{id_col}]",
        :id           => "#{obj.class.to_s.snake_case}_#{id_col}",
        :selected     => (obj.send(id_col) ? obj.send(id_col).to_s : nil),
        :prompt       => (attrs[:prompt] or "&lt;select a center&gt;")
      html.gsub('!!!', '&nbsp;')  # otherwise the &nbsp; entities get escaped
    end

    MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
    def date_select_for(obj, col, attrs = {})
      attrs.merge!(:name => "#{obj.class.to_s.snake_case}[#{col.to_s}]")
      attrs.merge!(:id   => "#{obj.class.to_s.snake_case}_#{col.to_s}")

      nullable = attrs[:nullable] ? true : false
      date = obj.send(col)
      date = Date.today if date.blank? and not nullable
      date = nil        if date.blank? and nullable
#       errorify_field(attrs, col)

      day_attrs = attrs.merge(
        :name       => attrs[:name] + '[day]',
        :id         => attrs[:id] + '_day',
        :selected   => (date ? date.day.to_s : ''),
        :class      => (obj.errors[col] ? 'error' : ''),
        :collection => (nullable ? [['', '-']] : []) + (1..31).to_a.map{ |x| x = [x.to_s, x.to_s] }
      )
      
      count = 0
      month_attrs = attrs.merge(
        :name       => attrs[:name] + '[month]',
        :id         => attrs[:id] + '_month',
        :selected   => (date ? date.month.to_s : ''),
        :class      => (obj.errors[col] ? 'error' : ''),
        :collection => (nullable ? [['', '-']] : []) + MONTHS.map { |x| count += 1; x = [count, x] }
      )
      
      year_attrs = attrs.merge(
        :name       => attrs[:name] + '[year]',
        :id         => attrs[:id] + '_year',
        :selected   => (date ? date.year.to_s : ''),
        :class      => (obj.errors[col] ? 'error' : ''),
        :collection => (nullable ? [['', '-']] : []) + (1900..Time.now.year).to_a.reverse.map{|x| x = [x.to_s, x.to_s]}
      )
      
      select(month_attrs) + '&nbsp;' + select(day_attrs) + '&nbsp;' + select(year_attrs)
    end


    def ofc2(width, height, url, id = Time.now.usec, swf_base = '/')
      <<-HTML
        <div id='flashcontent_#{id}'></div>
        <script type="text/javascript">
          swfobject.embedSWF(
            "#{swf_base}open-flash-chart.swf", "flashcontent_#{id}",
            "#{width}", "#{height}", "9.0.0", "expressInstall.swf",
            {"data-file":"#{url}", "loading":"Waiting for data... (reload page when it takes too long)"} );
        </script>
      HTML
    end

    def breadcrums
      # breadcrums use the request.uri and the instance vars of the parent
      # resources (@branch, @center) that are available -- so no db queries
      crums, url = [], ''
      request.uri[1..-1].split('/').each_with_index do |part, index|
        url  << '/' + part
        if part.to_i.to_s.length == part.length  # true when a number (id)
          o = instance_variable_get('@'+url.split('/')[-2].singular)  # get the object (@branch)
          s = (o.respond_to?(:name) ? link_to(o.name, url) : link_to('#'+o.id.to_s, url))
          crums[-1] += ": <b><i>#{s}</i></b>"  # merge the instance names (or numbers)
        else  # when not a number (id)
          crums << link_to(part.gsub('_', ' '), url)  # add the resource name
        end
      end
      ['', crums].join('&nbsp;<b>&gt;&gt;</b>&nbsp;')  # fancy separator
    end

    def format_currency(i)
      # in case of our rupees we do not count with cents, if you want to have cents do that here
      i.to_i.to_s + " INR"
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
  end
end
