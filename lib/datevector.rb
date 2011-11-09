class Date

  def next_(weekday, after = 1)
    # returns today + 7 if today is also the same weekday
    # this is to prevent us getting stuck in an endless loop
    
    # the :after parameter allows us to get the nth such weekday
    n  = self - self.wday + WEEKDAYS.index(weekday) + 1
    after += 1 if n <= self 
    return n + (7 * (after - 1))
  end

  def first_day_of_month
    self - self.day + 1
  end

  def last_day_of_month
    Date.new(self.month == 12 ? self.year + 1 : self.year, self.month == 12 ? 1 : self.month + 1, 1) - 1
  end

end

class DateVector

  # This class returns a string of dates given a periodicity
  # every <nth>, <mth> <weekday> of every <oth> week i.e. every Thursday, every second Tuesday
  # every <nth>, <mth>.... date of every <oth> month i.e. 12 and 29th of every month, 2nd of every other month
  # every <nth>, <mth> <weekday> of the month i.e. 2nd and 4th Friday

  # this will start from the first valid date within the date range
  attr_accessor :every, :what, :of_every, :period, :from, :to, :dates

  def initialize(every, what, of_every, period, from, to)
    # i.e. DateVector.new(1, [:tuesday, :thursday], 2, :week, d1, d2) => every second tuesday and thursday
    #                    ([2,4],[:tuesday, :thursday],2,:month, d1, d2) => every second and fourth tuesday and thursday of every second month
    @every = every
    @what = what
    @of_every = of_every
    @period = period
    @from = from
    @to = to
  end

  def get_next_n_dates(n, from = Date.today, override_to_date = false)
    # gets the next n dates from from date. Stops at @to unless you override_to_date
    ds = get_dates(from, n)
    override_to_date ? ds.select{|d| d <= @to} : ds
  end

  def get_dates(from = @from, to = @to)
    # get the dates as specified by this vector from the from date uptil "to" if "to" is a Date, or else get "to" such dates if an integer
    raise ArgumentError.new("from and must be a date") unless from.is_a?(Date) 
    raise ArgumentError.new("to must be either a date or an Integer") unless (to.is_a?(Date) or to.is_a? Integer)
    d = from;    rv = [];     i = 0
    case @period
    when :week
      while (to.is_a?(Date) ? d  <= to : i <= to)
        [@what].flatten.map do |wday| # convert :tuesday into [:tuesday] so we can treat everything as an array
          d = d.next_(wday)
          rv << d if (to.is_a?(Date) ? d  <= to : i <= to)
          d = d + ((@of_every - 1) * 7)
          i += 1
        end
      end
    when :month 
      if @what == :day
        # handle dates i.e. every => [15,22], what => :day, :of_every => 1, :period => :month means the 15th and 22nd of every month
        while d<= to
          [@every].flatten.each do |e|
            d = d.first_day_of_month + e - 1
            rv << d if d >= from and (to.is_a?(Date) ? d  <= to : i <= to)
          end
          d = (d.last_day_of_month + 1) >> (@of_every - 1)
          i += 1
        end          
      else
        # handle 2nd tuesday every 2nd month type. every = 2, what = :tuesday, :of_every = 2, :period = :month
        while d <= to
          [@every].flatten.each do |e|
            [@what].flatten.each do |w|
              d = d.first_day_of_month.next_(w,e)
              rv << d if d >= from and (to.is_a?(Date) ? d  <= to : i <= to)
            end
          end
          d = (d.last_day_of_month + 1) >> (@of_every - 1)
          i += 1
        end
        
      end
    end
    @dates = rv.select{|d| d >= from and (to.is_a?(Date) ? d <= to : true)}
  end




end
