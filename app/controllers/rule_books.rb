class RuleBooks < Application
  # provides :xml, :yaml, :js

  def index
    @rule_books = RuleBook.all.paginate(:page =>params[:page],:per_page => 15)
    display @rule_books, :layout => layout?
  end

  def show(id)
    @rule_book = RuleBook.get(id)
    raise NotFound unless @rule_book
    display @rule_book, :layout => layout?
  end

  def new
    only_provides :html
    @rule_book = RuleBook.new
    @branch    = Branch.get(params[:branch_id]) if params.key?(:branch_id)
    @accounts  = Account.all(:branch_id => params[:branch_id], :order => [:account_type_id]).map{|x| [x.id ,"#{x.account_type.name} -- #{x.name}"]}
    display @rule_book, :layout => layout?
  end

  def edit(id)
    only_provides :html
    @rule_book = RuleBook.get(id)
    raise NotFound unless @rule_book
    @accounts = Account.all(:branch_id => @rule_book.branch_id, :order => [:account_type_id]).map{|x| [x.id ,"#{x.account_type.name} -- #{x.name}"]}
    display @rule_book, :layout => layout?
  end

  def create(rule_book)
    rule_book, credit_accounts, debit_accounts = get_credit_and_debit_accounts(rule_book)
    @rule_book = RuleBook.new(rule_book)
    @rule_book.created_by_user_id = session.user.id
    credit_accounts.each{|ca| @rule_book.credit_account_rules << CreditAccountRule.new(:credit_account => ca[:account], :percentage => ca[:percentage])}
    debit_accounts.each{|da|  @rule_book.debit_account_rules  << DebitAccountRule.new(:debit_account => da[:account], :percentage => da[:percentage])}
    if @rule_book.save
      redirect(params[:return]||resource(:rule_books), :message => {:notice => "RuleBook was successfully created"})
    else
      @accounts = Account.all(:branch_id => params[:branch_id], :order => [:account_type_id]).map{|x| [x.id ,"#{x.account_type.name} -- #{x.name}"]}
      message[:error] = "RuleBook failed to be created"
      render :new
    end
  end

  def update(id, rule_book)
    rule_book, credit_accounts, debit_accounts = get_credit_and_debit_accounts(rule_book)

    @rule_book = RuleBook.get(id)
    raise NotFound unless @rule_book

    RuleBook.transaction do
      @rule_book.updated_by_user_id = session.user.id
      @rule_book.attributes = rule_book
      @rule_book.credit_accounts, @rule_book.debit_accounts = [], []
      credit_accounts.each{|ca|
        if car = @rule_book.credit_account_rules.find{|rule| rule.credit_account == ca[:account]}
          # found an existing credit accoutn rule. Update percentage value
          car.percentage = ca[:percentage]
        else
          @rule_book.credit_account_rules.push(CreditAccountRule.new(:credit_account_id => ca[:account].id, :percentage => ca[:percentage]))
        end
      }
      @rule_book.credit_account_rules.all(:credit_account_id.not => credit_accounts.map{|x| x[:account].id}).each{|dar|
        @rule_book.credit_account_rules.delete(dar)
      }

      debit_accounts.each{|da|
        if dar = @rule_book.debit_account_rules.find{|rule| rule.debit_account == da[:account]}
          # found an existing credit accoutn rule. Update percentage value
          dar.percentage = da[:percentage]
        else
          @rule_book.debit_account_rules.push(DebitAccountRule.new(:debit_account_id => da[:account].id, :percentage => da[:percentage]))
        end
      }
      @rule_book.debit_account_rules.all(:debit_account_id.not => debit_accounts.map{|x| x[:account].id}).each{|dar|
        @rule_book.debit_account_rules.delete(dar)
      }
    
      if @rule_book.save        
        redirect(params[:return]||resource(:rule_books))
      else
        display @rule_book, :edit
      end
    end
  end

  def destroy(id)
    @rule_book = RuleBook.get(id)
    raise NotFound unless @rule_book
    if @rule_book.destroy
      redirect resource(:rule_books)
    else
      raise InternalServerError
    end
  end

  def duplicate
    if request.method == :post
      @new_rules = params[:rules].map do |k,v|
        debit_acc = v.delete(:debit_accounts)
        credit_acc = v.delete(:credit_accounts)
        rb = RuleBook.new(v.merge({:created_by_user_id => session.user.id}))

        rb.credit_account_rules = credit_acc.map{|c_key, c_value|
          CreditAccountRule.new(:credit_account_id => c_value[:account_id], :percentage => c_value[:percentage])
        }

        rb.debit_account_rules = debit_acc.map{|d_key, d_value|
          DebitAccountRule.new(:debit_account_id => d_value[:account_id], :percentage => d_value[:percentage])
        }
        
        if v["active"] == "on" 
          rb.active = true
        else
          rb.active = false
        end
        
        rb.branch_id = params[:parent_branch_id]
        rb
      end

      RuleBook.transaction do |t|
        if @new_rules.map{|r|
            if RuleBook.all(:branch_id => params[:parent_branch_id], :from_date => r.from_date, :to_date => r.to_date, :action => r.action).empty?
              r.debit_account_rules.each{|x| x.save}
              r.save
              r.saved?
            else
              false
            end
          }.include?(false)
          t.rollback
          redirect url(:accounts), :message => {:error => "There were error/s in the creation of RuleBooks."} 
        else
          redirect url(:accounts), :message => {:notice => "Rule Books copied succesfully"}
        end
      end
    else
      unless params[:branch_id].blank?
        @branch = Branch.get(params[:branch_id])
        @new_branch = Branch.get(params[:new_branch_id])
        raise NotFound unless (@branch and @new_branch)
        @rule_books = RuleBook.all(:branch_id => params[:branch_id])
      end
      partial :duplicate
    end
  end

private
  def get_credit_and_debit_accounts(rule_book)
    if rule_book[:credit_accounts]
      credit_accounts = rule_book[:credit_accounts].reject{|k, ca| ca[:account_id].blank?}.map{|k, ca| 
        {:account => Account.get(ca[:account_id]), :percentage => ca[:percentage]}
      }.compact
      rule_book.delete(:credit_accounts)
    end

    if rule_book[:debit_accounts]
      debit_accounts  = rule_book[:debit_accounts].reject{|k, da| da[:account_id].blank?}.map{|k, da| 
        {:account => Account.get(da[:account_id]), :percentage => da[:percentage]}
      }.compact
      rule_book.delete(:debit_accounts)
    end
    rule_book.delete(:fee_id) if rule_book.key?(:fee_id) and (rule_book[:fee_id].blank? or rule_book[:action]!="fees")

    [rule_book, credit_accounts, debit_accounts]
  end
end # RuleBooks
