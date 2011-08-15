module Merb::Maintainer::LogsHelper

  def get_log(file, max_line_count, is_first_request)
    return get_log_content(file, max_line_count) if is_first_request == "true"

    previous_modified_time = File.mtime(file)
    while true do
      current_modified_time = File.mtime(file)
      return get_log_content(file, max_line_count) if previous_modified_time != current_modified_time
      sleep 1
    end
  end


  def get_log_content(file, max_line_count)
    content = File.readlines(file) || []
    (content.length > max_line_count) ? content[-max_line_count..-1].to_json : content.to_json
  end

  def get_parsed_watchable_files
    ret = []
    WATCHABLE_FILES.each { |glob| ret = ret | Dir.glob(glob) }
    return ret
  end

end
