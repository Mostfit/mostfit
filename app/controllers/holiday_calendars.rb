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
    if holiday_calendar.has_key?(:holiday) # just adding a holiday
      holiday = Holiday.get(holiday_calendar[:holiday])
      raise NotFound unless holiday
      @holiday_calendar.old_holidays = @holiday_calendar.holidays.dup
      @holiday_calendar.add_holiday(holiday)
      if @holiday_calendar.save
        redirect resource(@holiday_calendar), :message => {:notice => "Holiday added succesfully"}
      else
        redirect resource(@holiday_calendar), :message => {:error => "Holiday not added"}
      end
    else
      if @holiday_calendar.update(holiday_calendar)
        redirect resource(@holiday_calendar)
      else
        display @holiday_calendar, :edit
      end
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

  def delete_holiday(id, holiday_id)
    @holiday_calendar = HolidayCalendar.get(id)
    raise NotFound unless @holiday_calendar
    @holiday_calendar.remove_holiday(holiday_id)
    @holiday_calendar.save
    redirect resource(@holiday_calendar)
  end

end # HolidayCalendars

