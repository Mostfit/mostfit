class FundingLines < Application
  include DateParser
  before :get_context, :exclude => ['redirect_to_show']
  provides :xml, :yaml, :js

  def index
    @funding_lines = @funder.funding_lines
    display @funding_lines
  end

  def show(id)
    @funding_line = FundingLine.get(id)
    raise NotFound unless @funding_line
    display @funding_line
  end

  def new
    only_provides :html
    @funding_line = FundingLine.new
    display @funding_line
  end

  def create(funding_line)
    funding_line[:interest_rate] = funding_line[:interest_rate].to_f / 100
    @funding_line = FundingLine.new(funding_line)
    @funding_line.funder = @funder
    if @funding_line.save
      redirect resource(@funder, :funding_lines), :message => {:notice => "FundingLine was successfully created"}
    else
      render :new
    end
  end

  def edit(id)
    only_provides :html
    @funding_line = FundingLine.get(id)
    @funding_line.funder = @funder
    raise NotFound unless @funding_line
    display @funding_line
  end

  def update(id, funding_line)
    funding_line[:interest_rate] = funding_line[:interest_rate].to_f / 100
    @funding_line = FundingLine.get(id)
    raise NotFound unless @funding_line
    if @funding_line.update_attributes(funding_line)
       redirect resource(@funder, :funding_lines)
    else
      display @funding_line, :edit
    end
  end

#   def destroy(id)
#     @funding_line = FundingLine.get(id)
#     raise NotFound unless @funding_line
#     if @funding_line.destroy
#       redirect resource(:funding_lines)
#     else
#       raise InternalServerError
#     end
#   end

  # used from the router to redirect to a resourceful url
  def redirect_to_show(id)
    raise NotFound unless @funding_line = FundingLine.get(id)
    redirect resource(@funding_line.funder, @funding_line)
  end


  private
  # this works from proper resourceful urls
  def get_context
    @funder = Funder.get(params[:funder_id])
    raise NotFound unless @funder
  end
end # FundingLines
