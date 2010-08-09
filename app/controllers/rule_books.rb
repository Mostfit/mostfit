class RuleBooks < Application
  # provides :xml, :yaml, :js

  def index
    @rule_books = RuleBook.all.paginate(:page =>params[:page],:per_page => 5)
    display @rule_books
  end

  def show(id)
    @rule_book = RuleBook.get(id)
    raise NotFound unless @rule_book
    display @rule_book
  end

  def new
    only_provides :html
    @rule_book = RuleBook.new
    display @rule_book
  end

  def edit(id)
    only_provides :html
    @rule_book = RuleBook.get(id)
    raise NotFound unless @rule_book
    display @rule_book
  end

  def create(rule_book)
    rule_book, credit_accounts, debit_accounts = get_credit_and_debit_accounts(rule_book)
    @rule_book = RuleBook.new(rule_book)

    credit_accounts.each{|ca| @rule_book.credit_account_rules << CreditAccountRule.new(:credit_account => ca[:account], :percentage => ca[:percentage])}
    debit_accounts.each{|da|  @rule_book.debit_account_rules  << DebitAccountRule.new(:debit_account => da[:account], :percentage => da[:percentage])}

    if @rule_book.save
      redirect resource(:rule_books), :message => {:notice => "RuleBook was successfully created"}
    else
      message[:error] = "RuleBook failed to be created"
      render :new
    end
  end

  def update(id, rule_book)
    rule_book, credit_accounts, debit_accounts = get_credit_and_debit_accounts(rule_book)
    @rule_book = RuleBook.get(id)
    raise NotFound unless @rule_book
    RuleBook.transaction do
      @rule_book.attributes = rule_book
      @rule_book.credit_accounts, @rule_book.debit_accounts = [], []
      credit_accounts.each{|ca| @rule_book.credit_accounts << ca[:account]}
      debit_accounts.each{|da| @rule_book.debit_accounts << da[:account]}
      credit_accounts.each{|ca| @rule_book.credit_account_rules.find{|x| x.credit_account_id == ca[:account].id}.percentage=ca[:percentage]}
      debit_accounts.each{|da|  @rule_book.debit_account_rules.find{|x|  x.debit_account_id  == da[:account].id}.percentage=da[:percentage]}

      if @rule_book.save        
        redirect resource(:rule_books)
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
