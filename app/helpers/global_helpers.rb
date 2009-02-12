module Merb
  module GlobalHelpers

    def date_selector(col, attrs = {})

      attrs.merge!(:name => attrs[:name])
      attrs.merge!(:id   => attrs[:id])

      date = @_obj.send(col) || Time.new
      
      # TODO: Handle :selected option
      #attrs.merge!(:selected => attrs[:selected] || control_value(col))
      
      errorify_field(attrs, col)

      month_attrs = attrs.merge(
        :selected   => date.month.to_s, 
        :name       => attrs[:name] + '[month]',
        :id         => attrs[:id] + '_month',
        :collection => [1,2,3,4,5,6,7,8,9,10,11,12]
      )
      
      day_attrs = attrs.merge(
        :selected   => date.day.to_s, 
        :name       => attrs[:name] + '[day]',
        :id         => attrs[:id] + '_day',
        :collection => (1..31).to_a,
        :label      => nil
      )
      
      year_attrs = attrs.merge(
        :selected   => date.year.to_s,
        :name       => attrs[:name] + '[year]',
        :id         => attrs[:id] + '_year',
        :collection => (1970..2020).to_a,
        :label      => nil
      )
      
      select_field(day_attrs) + select_field(month_attrs) + select_field(year_attrs)
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
