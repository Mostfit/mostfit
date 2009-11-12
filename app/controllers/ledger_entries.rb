class LedgerEntries < Application
  # provides :xml, :yaml, :js

  def index
    @ledger_entries = LedgerEntry.all
    display @ledger_entries
  end

  def show(id)
    @ledger_entry = LedgerEntry.get(id)
    raise NotFound unless @ledger_entry
    display @ledger_entry
  end

  def new
    only_provides :html
    @ledger_entry = LedgerEntry.new
    display @ledger_entry
  end

  def edit(id)
    only_provides :html
    @ledger_entry = LedgerEntry.get(id)
    raise NotFound unless @ledger_entry
    display @ledger_entry
  end

  def create(ledger_entry)
    @ledger_entry = LedgerEntry.new(ledger_entry)
    if @ledger_entry.save
      redirect resource(@ledger_entry), :message => {:notice => "LedgerEntry was successfully created"}
    else
      message[:error] = "LedgerEntry failed to be created"
      render :new
    end
  end

  def update(id, ledger_entry)
    @ledger_entry = LedgerEntry.get(id)
    raise NotFound unless @ledger_entry
    if @ledger_entry.update(ledger_entry)
       redirect resource(@ledger_entry)
    else
      display @ledger_entry, :edit
    end
  end

  def destroy(id)
    @ledger_entry = LedgerEntry.get(id)
    raise NotFound unless @ledger_entry
    if @ledger_entry.destroy
      redirect resource(:ledger_entries)
    else
      raise InternalServerError
    end
  end

end # LedgerEntries
