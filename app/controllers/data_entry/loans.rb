module DataEntry

class Loans < DataEntry::Controller
  def new
    @loan = Loan.new
    render
  end

  def create
  end

  def edit
  end

  def update
  end

  def delete
  end

  def destroy
  end
end

end