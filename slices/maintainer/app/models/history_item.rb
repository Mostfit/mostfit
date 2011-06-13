class Maintainer::HistoryItem

  include DataMapper::Resource
  include Merb::Helpers::DateAndTime
  
  ACTIONS = ['took_snapshot', 'downloaded_dump']
  
  property :id,         Serial
  property :user_name,  String,   :nullable => false
  property :ip,         String,   :nullable => false
  property :time,       DateTime, :nullable => false
  property :action,     String,   :nullable => false, :set => ACTIONS
  property :data,       String
  
  def stringify
    action_description = case action
                         when 'took_snapshot'
                           "took a database snapshot"
                         when 'downloaded_dump'
                           "downloaded a database dump"
                         end
    
    desc = "#{user_name} #{action_description} "
    desc += "(#{data}) " if data
    desc += "from #{ip} <a href='#' title='#{time.strftime("%l:%M:%S %p, %d %b, %Y")}'>#{time_lost_in_words(time).sub(/\.0+/,"")} ago</a>"
  end
  
end
