class Journals < Application
  before :get_context

  # provides :xml, :yaml, :js
  def index
    @journals = Journal.all(:order => [:created_at.desc]).paginate(:per_page => 20, :page => params[:page] ||1 )
    display @journals, :layout => layout?
  end

  def new
    only_provides :html
    @journal = Journal.new
    display @journal, :layout => layout?
  end

  def add_account
    @branch = (params[:branch_id] ? Branch.get(params[:branch_id]) : nil)
    partial :account_amount, :layout => layout?, :last_account => true, :account_type => (params[:account_type]||"credit_account").to_sym, :account => {}
  end

  def create(journal)
    @branch  = Branch.get(params[:branch_id]) if params[:branch_id]

    if params[:debit_account] and params[:credit_account]
      #single debit and single credit accounts
      debit_accounts  = Account.get(params[:debit_account][:account_id])
      credit_accounts = Account.get(params[:credit_account][:account_id])
    elsif params[:debit_accounts] and params[:credit_accounts]
      #multiple debit and credit accounts
      debit_accounts, credit_accounts  = {}, {}
      params[:debit_accounts].each{|debit|
        debit_accounts[Account.get(debit[:account_id])] = debit[:amount].to_i
      }
      params[:credit_accounts].each{|credit|
        credit_accounts[Account.get(credit[:account_id])] = credit[:amount].to_i      
      }
    end

    journal[:currency] = Currency.first
    status, @journal = Journal.create_transaction(journal, debit_accounts, credit_accounts)

    if status
      if params[:return] and not params[:return].blank?
        redirect params[:return], :message => {:notice => "Journal was successfully created"}        
      elsif @branch
        redirect resource(@branch), :message => {:notice => "Journal was successfully created"}
      else
        redirect resource(:accounts)+"#journal_entries", :message => {:notice => "Journal was successfully created"}
      end
    else
      message[:error] = "Journal failed to be created"
      render :new
    end
  end

  def edit(id)
    only_provides :html
    @journal = Journal.get(id)
    raise NotFound unless @journal
    display @journal, :layout => layout?
  end

  def update(id, journal)
    @journal = Journal.get(id)
    raise NotFound unless @journal
    if @journal.update_attributes(journal)
      redirect resource(:journals), :message => {:notice => "Journal was successfully edited"}
    else
      message[:error] = "Journal could not be edited"
      redirect resource(:journals)
    end
  end

private
  def get_context
    @branch       = Branch.get(params[:branch_id]) if params[:branch_id]
  end
end # Journals
