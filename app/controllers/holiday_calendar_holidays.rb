class HolidayCalendarHolidays < Application
  # provides :xml, :yaml, :js

  def index
    @holiday_calendar_holidays = HolidayCalendarHoliday.all
    display @holiday_calendar_holidays
  end

  def show(id)
    @holiday_calendar_holiday = HolidayCalendarHoliday.get(id)
    raise NotFound unless @holiday_calendar_holiday
    display @holiday_calendar_holiday
  end

  def new
    only_provides :html
    @holiday_calendar_holiday = HolidayCalendarHoliday.new
    display @holiday_calendar_holiday
  end

  def edit(id)
    only_provides :html
    @holiday_calendar_holiday = HolidayCalendarHoliday.get(id)
    raise NotFound unless @holiday_calendar_holiday
    display @holiday_calendar_holiday
  end

  def create(holiday_calendar_holiday)
    @holiday_calendar_holiday = HolidayCalendarHoliday.new(holiday_calendar_holiday)
    if @holiday_calendar_holiday.save
      redirect resource(@holiday_calendar_holiday), :message => {:notice => "HolidayCalendarHoliday was successfully created"}
    else
      message[:error] = "HolidayCalendarHoliday failed to be created"
      render :new
    end
  end

  def update(id, holiday_calendar_holiday)
    @holiday_calendar_holiday = HolidayCalendarHoliday.get(id)
    raise NotFound unless @holiday_calendar_holiday
    if @holiday_calendar_holiday.update(holiday_calendar_holiday)
       redirect resource(@holiday_calendar_holiday)
    else
      display @holiday_calendar_holiday, :edit
    end
  end

  def destroy(id)
    @holiday_calendar_holiday = HolidayCalendarHoliday.get(id)
    raise NotFound unless @holiday_calendar_holiday
    if @holiday_calendar_holiday.destroy
      redirect resource(:holiday_calendar_holidays)
    else
      raise InternalServerError
    end
  end

end # HolidayCalendarHolidays
