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
    @rule_book = RuleBook.new(rule_book)
    if @rule_book.save
      redirect resource(:rule_books), :message => {:notice => "RuleBook was successfully created"}
    else
      message[:error] = "RuleBook failed to be created"
      render :new
    end
  end

  def update(id, rule_book)
    @rule_book = RuleBook.get(id)
    raise NotFound unless @rule_book
    if @rule_book.update(rule_book)
       redirect resource(:rule_books)
    else
      display @rule_book, :edit
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

end # RuleBooks
