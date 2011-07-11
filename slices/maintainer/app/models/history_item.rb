class Maintainer::HistoryItem

  include DataMapper::Resource
  include Merb::Helpers::DateAndTime
  
  ACTIONS = {
    'took_snapshot'           => 'took a database snapshot',
    'downloaded_dump'         => 'downloaded a database dump',
    'deleted_dump'            => 'deleted a database dump',
    'created_task'            => 'created a scheduled task',
    'edited_task'             => 'edited a scheduled task',
    'deleted_task'            => 'deleted a scheduled task',
    'deployed'                => 'performed a deployment',
    'deployed_and_upgraded'   => 'performed a database upgrade and deployment',
    'rollback'                => 'performed a rollback'
  }
  
  property :id,         Serial
  property :user_name,  String,   :nullable => false
  property :ip,         String,   :nullable => false
  property :time,       DateTime, :nullable => false
  property :action,     String,   :nullable => false, :set => ACTIONS.keys
  property :data,       String
  
  def stringify
    desc = "#{user_name} #{ACTIONS[action]} "
    if data
      if action == 'deployed' or action == 'deployed_and_upgraded' or action == 'rollback'
        deployment = DM_REPO.scope { Maintainer::DeploymentItem.first(:sha => data) }
        desc += "(<a href='#' title='#{data}'>#{data.truncate(10)}</a> "
        desc += (deployment) ? "in branch '#{deployment.branch}') " : ") "
      else
        desc += "(#{data}) "
      end
    end
    desc += "from #{ip} <a href='#' title='#{time.strftime(DATE_FORMAT_READABLE)}' class='time'>#{time_lost_in_words(time).sub(/\.0+/,"")} ago</a>"
  end
  
end
