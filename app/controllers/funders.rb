class Funders < Application
  provides :xml, :yaml, :js

  def index
    @funders = Funder.all
    display @funders
  end

  def show(id)
    @funder = Funder.get(id)
    raise NotFound unless @funder
    @funding_lines = @funder.funding_lines
    display [@funder, @funding_lines], 'funding_lines/index'
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
