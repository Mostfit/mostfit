class Accounts < Application
  # provides :xml, :yaml, :js
  before :get_context

  # TODO the recursive functions need to be debugged and have to be used a display fully nested accounting selection box
  # def hash_creation(account, hash_list)
  #     if account.children
  #       hash_list[account]||={}
  #       account.children.each{|c|
  #       hash_creation(c, hash_list[c])
  #     }
  #     else 
  #       hash_list[account] = account.children
  #     end
  # end

  # def list_creation(account, list)
  #     if account.children
  #       account.children.each{|c|
  #       list_creation(c, list)
  #     }
  #     else 
  #       list << account.children
  #     end
  # end

  def index
    if params[:branch_id] and not params[:branch_id].blank?
      @branch =  Branch.get(params[:branch_id])
    else
      @branch = nil
    end
    @accounts = Account.tree((params[:branch_id] and not params[:branch_id].blank?) ? params[:branch_id].to_i : nil )
    if params[:account_type_id] and (not params[:account_type_id].blank?)
      @accounts = @accounts.delete(AccountType.get(params[:account_type_id])).to_hash
    end
    template = request.xhr? ? 'accounts/select' : 'accounts/index'
    display @accounts, template, :layout => layout?
  end

  def show(id)
    @account = Account.get(id)
    raise NotFound unless @account
    display @account, :layout => layout?
  end

  def new
    only_provides :html
    @account = Account.new
    display @account, :layout => layout?
  end

  def edit(id)
    only_provides :html
    @account = Account.get(id)
    raise NotFound unless @account
 
    if @account.account_type
      @branch = Branch.get(@account.branch_id) if @account.branch_id
      @accounts = Account.tree(@account.branch_id || nil)
    end
    display @account, :layout => layout?
  end

  def create(account)
    if account.is_a?(Hash)
      @account = Account.new(account)
      if @account.save
        redirect resource(:accounts), :message => {:notice => "Account was successfully created"}
      else
        message[:error] = "Account failed to be created"
        render :new
      end
    elsif account.is_a?(Array)
      #bulk creating accounts
      if (params[:branch_id] and branch = Branch.get(params[:branch_id]))
        errors = bulk_create_for(branch, account)
        if errors.blank?
          redirect resource(:accounts), :message => {:notice => "All accounts were successfully created"}
        else
          message[:error] = "Some accounts failed to be created"
          message[:error] += "<ul>"
          errors.each{|error|
            message[:error] += error.instance_variable_get("@errors").map{|k, v| "<li>#{error.name} - #{k}: #{v}</li>"}.to_s
          }
          message[:error] += "</ul>"
          @branch = Branch.get(params[:parent_branch_id])
          @accounts = Account.all(:branch => @branch) if @branch     
          render :duplicate
        end
      else
        message[:error] = "No branch selected"
        @branch = Branch.get(params[:parent_branch_id])
        @accounts = Account.all(:branch => @branch) if @branch
        render :duplicate
      end
    end
  end

  def update(id, account)
    @account = Account.get(id)
    raise NotFound unless @account
    if @account.update(account)
       redirect resource(:accounts)
    else
      display @account, :edit
    end
  end

  def destroy(id)
    @account = Account.get(id)
    raise NotFound unless @account
    if @account.destroy
      redirect resource(:accounts)
    else
      raise InternalServerError
    end
  end

  def branch
    @journal = Journal.new
    render :layout => layout?
  end

  def duplicate
    unless params[:branch_id].blank?
      @branch = Branch.get(params[:branch_id])
      raise NotFound unless @branch
      @accounts = Account.all(:branch_id => params[:branch_id])
    end
    render :layout => layout?
  end

  def book
    if params[:accounting_period_id] and not params[:accounting_period_id].blank?
      @accounting_period = AccountingPeriod.get(params[:accounting_period_id])
    else
      @accounting_period = AccountingPeriod.all(:order => [:end_date]).last
    end
    @account = Account.get(params[:account_id])
    @from_date = (@accounting_period ? @accounting_period.begin_date : @account.account_earliest_date - 1)
    @to_date =  (@accounting_period ? @accounting_period.end_date : Date.today)
    @posting_hash = Posting.all(:account => @account, "journal.date.lte" => @to_date, "journal.date.gte" => @from_date).paginate(:page => params[:page], :per_page => 20)
    partial :book, :layout => layout?
  end

  private
  def get_context
    @branches_list = Branch.all.map{ |x| [x.id, x.name]}
    @branches_list.unshift([0, 'Head Office Accounts'])
    @branch = Branch.get(params[:branch_id]) if params.key?(:branch_id)
  end

  def bulk_create_for(branch, accounts)
    errors = []
    accounts.each{|a|
      new_account = Account.new(a)
      new_account.branch = branch
      unless new_account.save
        errors.push(new_account)
      end
    }
    errors
  end

end # Accounts
