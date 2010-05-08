module Merb
  module BookmarksHelper
    def transform_raw_post_to_hidden_fields(data)
      CGI.unescape(data).split('&').collect{|x| x.split('=')}.reject{|x| x[0]=='submit'}.map{|x| "<input type='hidden' name='#{x[0]}' value='#{x[1]}'>"}.join
    end
  end
end # Merb
