class HolidayCalendars < Application
  # provides :xml, :yaml, :js

  def index
    @holiday_calendars = HolidayCalendar.all
    display @holiday_calendars
  end

  def show(id)
    @holiday_calendar = HolidayCalendar.get(id)
    raise NotFound unless @holiday_calendar
    display @holiday_calendar
  end

  def new
    only_provides :html
    @holiday_calendar = HolidayCalendar.new
    display @holiday_calendar
  end

  def edit(id)
    only_provides :html
    @holiday_calendar = HolidayCalendar.get(id)
    raise NotFound unless @holiday_calendar
    display @holiday_calendar
  end

  def create(holiday_calendar)
    @holiday_calendar = HolidayCalendar.new(holiday_calendar)
    if @holiday_calendar.save
      redirect resource(@holiday_calendar), :message => {:notice => "HolidayCalendar was successfully created"}
    else
      message[:error] = "HolidayCalendar failed to be created"
      render :new
    end
  end

  def update(id, holiday_calendar)
    @holiday_calendar = HolidayCalendar.get(id)
    raise NotFound unless @holiday_calendar
    if @holiday_calendar.update(holiday_calendar)
       redirect resource(@holiday_calendar)
    else
      display @holiday_calendar, :edit
    end
  end

  def destroy(id)
    @holiday_calendar = HolidayCalendar.get(id)
    raise NotFound unless @holiday_calendar
    if @holiday_calendar.destroy
      redirect resource(:holiday_calendars)
    else
      raise InternalServerError
    end
  end

end # HolidayCalendars
