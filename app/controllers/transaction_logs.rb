class TransactionLogs < Application
  provides :xml, :yaml, :js
  
  def index
    render
  end
  
  def show(id)
    @transaction_log = TransactionLog.get(id)
    raise NotFound unless @transaction_log
    display @transaction_log
  end
end
