class Portfolios < Application
  # provides :xml, :yaml, :js
  before :get_context

  def index
    @portfolios = Portfolio.all
    redirect resource(@funder)
  end

  def show(id)
    @portfolio = Portfolio.get(id)
    @portfolio.update_portfolio_value
    raise NotFound unless @portfolio
    @funder    = @portfolio.funder
    display @portfolio
  end

  def new
    only_provides :html    
    @portfolio = Portfolio.new
    @data      = @portfolio.eligible_loans
    @centers   = []
    display @portfolio
  end

  def edit(id)
    only_provides :html
    @portfolio = Portfolio.get(id)
    raise NotFound unless @portfolio
    disallow_updation_of_verified_portfolios
    @data      = @portfolio.eligible_loans
    @centers   = Center.all(:id => LoanHistory.ancestors_of_portfolio(@portfolio, Center))
    display @portfolio
  end

  def create(portfolio)
    @portfolio = Portfolio.new(portfolio)
    @portfolio.funder = @funder
    @portfolio.created_by = session.user

    if @portfolio.save_self
      redirect resource(@funder), :message => {:notice => "Portfolio was successfully created"}
    else
      @data = @portfolio.eligible_loans
      @centers = @portfolio.centers
      message[:error] = "Portfolio failed to be created"
      render :new
    end
  end

  def update(id, portfolio)
    @portfolio = Portfolio.get(id)
    raise NotFound unless @portfolio
    @portfolio.attributes = portfolio
    if @portfolio.save_self
       redirect resource(@funder)
    else
      @data = @portfolio.eligible_loans
      display @portfolio, :edit
    end
  end

  def destroy(id)
    @portfolio = Portfolio.get(id)
    raise NotFound unless @portfolio
    if @portfolio.destroy
      redirect resource(:portfolios)
    else
      raise InternalServerError
    end
  end

  # def loans
  #   @portfolio = params[:id] ? Portfolio.get(params[:id]) : Portfolio.new
  #   @loans     = @portfolio.eligible_loans(params[:center_id])
  #   render :layout => layout?
  # end

  private
  def get_context
    if params[:funder_id] and not params[:funder_id].blank?
      @funder = Funder.get(params[:funder_id])
      raise NotFound unless @funder
    end
  end
  def disallow_updation_of_verified_portfolios
    raise NotChangeable if @portfolio.verified_by_user_id
  end
end # Portfolios
