class Occupations < Application
  # provides :xml, :yaml, :js

  def index
    @occupations = Occupation.all
    display @occupations
  end

  def show(id)
    @occupation = Occupation.get(id)
    raise NotFound unless @occupation
    display @occupation
  end

  def new
    only_provides :html
    @occupation = Occupation.new
    display @occupation
  end

  def edit(id)
    only_provides :html
    @occupation = Occupation.get(id)
    raise NotFound unless @occupation
    display @occupation
  end

  def create(occupation)
    @occupation = Occupation.new(occupation)
    if @occupation.save
      redirect resource(:occupations), :message => {:notice => "Occupation was successfully created"}
    else
      message[:error] = "Occupation failed to be created"
      render :new
    end
  end

  def update(id, occupation)
    @occupation = Occupation.get(id)
    raise NotFound unless @occupation
    if @occupation.update(occupation)
      redirect resource(:occupations), :message => {:notice => "Occupation was updated"}
    else
      display @occupation, :edit
    end
  end

  def destroy(id)
    @occupation = Occupation.get(id)
    raise NotFound unless @occupation
    if @occupation.destroy
      redirect resource(:occupations)
    else
      raise InternalServerError
    end
  end

end # Occupations
