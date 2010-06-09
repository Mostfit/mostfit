class Accountings < Application
  # provides :xml, :yaml, :js

  def index
    @accountings = Accounting.all
    display @accountings
  end

  def show(id)
    @accounting = Accounting.get(id)
    raise NotFound unless @accounting
    display @accounting
  end

  def new
    only_provides :html
    @accounting = Accounting.new
    display @accounting
  end

  def edit(id)
    only_provides :html
    @accounting = Accounting.get(id)
    raise NotFound unless @accounting
    display @accounting
  end

  def create(accounting)
    @accounting = Accounting.new(accounting)
    if @accounting.save
      redirect resource(@accounting), :message => {:notice =>"Accounting was successfully created"}
    else
      message[:error] = "Accounting failed to be created"
      render :new
    end
  end

  def update(id, accounting)
    @accounting = Accounting.get(id)
    raise NotFound unless @accounting
    if @accounting.update(accounting)
       redirect resource(@accounting)
    else
      display @accounting, :edit
    end
  end

  def destroy(id)
    @accounting = Accounting.get(id)
    raise NotFound unless @accounting
    if @accounting.destroy
      redirect resource(:accountings)
    else
      raise InternalServerError
    end
  end

end # Accountings
