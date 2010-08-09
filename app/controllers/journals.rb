class Journals < Application
  before :get_context

  # provides :xml, :yaml, :js
  def index
    @journals = Journal.all.paginate(:per_page => 10, :page => params[:page] ||1 )
    display @journals
  end

  def new
    only_provides :html
    @journal = Journal.new
    display @journal, :layout => layout?
  end

  def create(journal)
    debit_account  = Account.get(params[:debit_account][:account_id])
    credit_account = Account.get(params[:credit_account][:account_id])
    journal[:currency] = Currency.first
    status, @journal = Journal.create_transaction(journal, debit_account, credit_account)
    if status
      if @branch
        redirect resource(@branch), :message => {:notice => "Journal was successfully created"}
      else
        redirect resource(:journals, :new), :message => {:notice => "Journal was successfully created"}
      end
    else
      message[:error] = "Journal failed to be created"
      render :new
    end
  end


private
  def get_context
    @branch       = Branch.get(params[:branch_id]) if params[:branch_id]
  end
end # Journals
