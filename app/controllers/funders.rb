class Funders < Application
  provides :xml, :yaml, :js

  def index
    @funders = @funders || Funder.all
    display @funders
  end

  def show(id)
    @funder ||= Funder.get(id)
    raise NotFound unless @funder
    @funding_lines = @funder.funding_lines
    @portfolios    = @funder.portfolios
    display [@funder, @funding_lines]
  end

  def new
    only_provides :html
    @funder = Funder.new
    display @funder
  end

  def create(funder)
    @funder = Funder.new(funder)
    if @funder.save
      redirect resource(:funders), :message => {:notice => "Funder #{@funder.name} was successfully created"}
    else
      render :new
    end
  end

  def edit(id)
    only_provides :html
    @funder = Funder.get(id)
    raise NotFound unless @funder
    display @funder
  end

  def update(id, funder)
    @funder = Funder.get(id)
    raise NotFound unless @funder
    if @funder.update_attributes(funder)
       redirect resource(:funders)
    else
      display @funder, :edit
    end
  end

  def funding_lines
    if params[:id]
      funder = Funder.get(params[:id])
      next unless funder
      return("<option value=''>Select funding lines</option>"+funder.funding_lines.map{|fl| "<option value=#{fl.id}>#{fl.name}</option>"}.join)
    end
  end

#   def destroy(id)
#     @funder = Funder.get(id)
#     raise NotFound unless @funder
#     if @funder.destroy
#       redirect resource(:funders)
#     else
#       raise InternalServerError
#     end
#   end

end # Funders
