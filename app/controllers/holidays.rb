class Holidays < Application
  # provides :xml, :yaml, :js

  def index
    @holidays = Holiday.all
    display @holidays
  end

  def show(id)
    @holiday = Holiday.get(id)
    raise NotFound unless @holiday
    display @holiday
  end

  def new
    only_provides :html
    @holiday = Holiday.new
    display @holiday
  end

  def edit(id)
    only_provides :html
    @holiday = Holiday.get(id)
    raise NotFound unless @holiday
    display @holiday
  end

  def create(holiday)
    @holiday = Holiday.new(holiday)
    if @holiday.save
      redirect resource(@holiday), :message => {:notice => "Holiday was successfully created"}
    else
      message[:error] = "Holiday failed to be created"
      render :new
    end
  end

  def update(id, holiday)
    @holiday = Holiday.get(id)
    raise NotFound unless @holiday
    if @holiday.update(holiday)
      redirect resource(@holiday)
    else
      display @holiday, :edit
    end
  end

  def destroy(id)
    @holiday = Holiday.get(id)
    raise NotFound unless @holiday
    if @holiday.destroy
      redirect resource(:holidays)
    else
      raise InternalServerError
    end
  end

end # Holidays
