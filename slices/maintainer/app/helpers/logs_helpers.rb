module Merb::Maintainer::LogsHelper

  def get_log(file, is_first_request)
    return get_log_content(file) if is_first_request == "true"

    previous_modified_time = File.mtime(file)
    while true do
      current_modified_time = File.mtime(file)
      return get_log_content(file) if previous_modified_time != current_modified_time
      sleep 1
    end
  end

  def get_log_content(file)
    content = File.readlines(file) || []
    (content.length > MAX_LINE_COUNT) ? content[-MAX_LINE_COUNT..-1].to_json : content.to_json
  end

end
