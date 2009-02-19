class FundingLines < Application
  # provides :xml, :yaml, :js

  def index
    @funding_lines = FundingLine.all
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

  def edit(id)
    only_provides :html
    @funding_line = FundingLine.get(id)
    raise NotFound unless @funding_line
    display @funding_line
  end

  def create(funding_line)
    @funding_line = FundingLine.new(funding_line)
    if @funding_line.save
      redirect resource(@funding_line), :message => {:notice => "FundingLine was successfully created"}
    else
      message[:error] = "FundingLine failed to be created"
      render :new
    end
  end

  def update(id, funding_line)
    @funding_line = FundingLine.get(id)
    raise NotFound unless @funding_line
    if @funding_line.update_attributes(funding_line)
       redirect resource(@funding_line)
    else
      display @funding_line, :edit
    end
  end

  def destroy(id)
    @funding_line = FundingLine.get(id)
    raise NotFound unless @funding_line
    if @funding_line.destroy
      redirect resource(:funding_lines)
    else
      raise InternalServerError
    end
  end

end # FundingLines
