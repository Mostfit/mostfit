class ModelEventLogs < Application
  provides :xml, :yaml, :js
  
  def index
    render
  end
  
  def show(id)
    @model_event_log = ModelEventLog.get(id)
    raise NotFound unless @model_event_log
    display @model_event_log
  end
  
end
