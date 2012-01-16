# small monkey patch, real patch is submitted to extlib/merb/dm, hoping for inclusion soon



class NilClass
  def to_currency
    "-"
  end

  def to_account_balance
    "-"
  end

end

class Date
  def display(style = nil, pattern = nil)
    mfi = Mfi.first
    style = style || mfi.prefered_date_style || DEFAULT_DATE_STYLE
    if pattern
      raise NotSupportedPattern if style == DEFAULT_DATE_STYLE and not PREFERED_DATE_PATTERNS.include?(pattern)
      self.strftime(pattern)
    else
      case style
      when "MEDIUM"
        self.strftime(MEDIUM_DATE_PATTERN)
      when "LONG"
        self.strftime(LONG_DATE_PATTERN)
      when "FULL"
        self.strftime(FULL_DATE_PATTERN)
      else
        # default short style
        pattern =  (mfi.prefered_date_pattern if not mfi.prefered_date_pattern.blank?) || DEFAULT_DATE_PATTERN
        separator = (mfi.prefered_date_separator if not mfi.prefered_date_separator.blank?) || DEFAULT_DATE_SEPARATOR
        pattern = pattern.to_s.gsub(FORMAT_REG_EXP, separator.to_s)
        self.strftime(pattern)
      end
    end
  end

  def inspect
   "<Date: #{self.to_s} #{self.weekday}>"
 end

 def weekday
  #week starts on monday
  WEEKDAYS[cwday - 1]
end

def is_holiday?
  Holiday.all.include?(self)
end

def count_weekday_uptil(weekday, d2)
  return 0 if d2 < self
  num_weeks = ((d2 - self) / 7).floor
  d_ = self + num_weeks
  add_one = ((d_.cwday)..((d2.cwday < d_.cwday ? 7 : d2.cwday))).include?(WEEKDAYS.index(weekday) + 1) ? 1 : 0
  num_weeks + add_one
end

def holiday_bump(direction = nil)
  # this is deprecated.
  # we no longer bump holidays. for each holiday we replace the date with the new date
  # and so we never have to call this function.
  # to deprecte, simple return the original date
  return self
  # hols = $holidays
  # new_date = self
  # return new_date unless hols
  # while hols.keys.include?(new_date)
  #   direction ||= hols[new_date].shift_meeting
  #   case direction
  #     when :before
  #       new_date -= 1 
  #     when :after
  #       new_date += 1
  #   end
  # end
  # return new_date
end  

def holidays_shifted_today
  return self-1 if was_yesterday_holiday_shifted_today?
  return self+1 if is_tommorow_holiday_shifted_today?
  return self
end

def weekdays
  days       = []
  days      << self.weekday
  days      << self.holidays_shifted_today.weekday
  days.uniq
end

def to_yaml( opts={} )
  YAML::quick_emit( self, opts ) do |out|
    out.scalar( "tag:yaml.org,2002:timestamp", self.strftime("%Y-%m-%d"), :plain )
  end
end

def days360(other)
  y1 = self.year;   y2 = other.year
  m1 = self.month;  m2 = other.month
  d1 = self.day;    d2 = other.day

  d1 = (d1 == 31) ? 30 : d1
  d2 = (d2 == 31) ? 30 : d2

  360 * (y2-y1) + 30 * (m2-m1) + (d2-d1)
end

# def self.min_date
#   Mfi.first.in_operation_since||Date.new(2000, 01, 01)
# end

# def self.max_date
#   today+1000
# end

private
def was_yesterday_holiday_shifted_today?
  yesterday = self-1
  return true if $holidays[yesterday] and $holidays[yesterday].shift_meeting==:after
  return false
end

def is_tommorow_holiday_shifted_today?
  yesterday = self+1
  return true if $holidays[yesterday] and $holidays[yesterday].shift_meeting==:before
  return false
end
end

module Misfit
  module Config
    attr_accessor :hols

    def self.compile_nomentculature
      if Mfi.first.center_manager
        name = Mfi.first.center_manager
      else
        name = "manager"
      end

      define_method :center_manager do
        name
      end
    end

    def self.holidays
      @hols ||= Holiday.all.map{|h| [h.date, h]}.to_hash
    end

    def self.refresh_holidays
      @hols = nil
    end
  end
end

class Hash

  # a function to turn {[:a, :b, :c] => 123, [:a, :b, :d] => 456} into {:a => {:b => {:c => 123, :d => 456}}}
  # very useful when bucketing and dealing with composite_key_sum group by from LoanHistory
  def deepen
    result = self.class.new

    each do |key, value|
      if key.is_a? Array and key.length > 1
        if result[key[0]]
          result[key[0]] += {key[1..-1] => value}.deepen
        else
          result[key[0]] = {key[1..-1] => value}.deepen
        end
      else
        result[key.is_a?(Array) ? key[0] : key] = value
      end
    end

    result
  end


  #Hash diffs are easy
  def diff(other)
    keys = self.keys
    keys.each.select{|k| self[k] != other[k]}
  end

  def / (other)
    rhash = {}
    keys.each do |k|
      if self.has_key?(k) and other.has_key?(k)
        rhash[k] = self[k]/other[k]
      else
        rhash[k] = nil
      end
    end
    rhash
  end

  def - (other)
    rhash = {}
    keys.each do |k|
      if has_key?(k) and other.has_key?(k)
        rhash[k] = self[k] - other[k]
      else
        rhash[k] = self[k]
      end
    end
    rhash
  end


  def +(other)
    rhash = {}
    (keys + other.keys).uniq.each do |k|
      if has_key?(k) and other.has_key?(k)
        if self[k].respond_to?(:+) and other[k].respond_to?(:+)
          rhash[k] = self[k] + other[k] rescue self[k]
        end
        # FIXME: no else clause?  so the key is dropped if not both have '+' implemented..  maybe simply the true clause (with rescue tail) suffices for all cases.
      else  # use the value of the hash that knows its key
        rhash[k] = other.has_key?(k) ? other[k] : self[k]
      end
    end
    rhash
  end

end


class String
  def join_snake(str='')
    self.split('_').map{|x| x}.join(str)
  end

  def camelcase(str='')
    self.split('_').map{|x| x.capitalize}.join(str)
  end
end


class Numeric
  alias_method :round_orig, :round
  def round(n=0)
    (self * (10.0 ** n)).round_orig * (10.0 ** (-n))
  end

  def to_account_balance
    as_currency = self.abs.to_currency
    (self < 0) ? "#{as_currency} Dr" : (self > 0) ? "#{as_currency} Cr" : "#{as_currency}"
  end
end


class Integer
  alias_method :round_orig, :round
  def round(n=0)
    (self * (10.0 ** n)).round_orig * (10.0 ** (-n))
  end
end


class Float
  alias_method :round_orig, :round
  def round(n=0)
    (self * (10.0 ** n)).round_orig * (10.0 ** (-n))
  end

  def round_to_nearest(i = nil, style = :round)
    return self if i.nil?
    return self unless self.respond_to?(style)
    (self / i).send(style) * i
  end
end


class Array
  # Takes a function and groups by a nested array return by dm-aggrgates using the given function
  def group_by_function(func)
    group_by{|x|
      func.call(x[0])
      }.map{|k,v|
        [k, v.map{|x| x[1]}.reduce{|s,x|
         s+=x
         }]
         }.sort_by{|x| x[0]}
       end

       def sum
        self.reduce(:+)
      end

      def chunk len
        a = []
        each_with_index do |x,i|
          a << [] if i % len == 0
          a.last << x
        end
        a
      end

    end


    module ExcelFormula
      def pmt(interest, installments, present_value, future_value, paid_before=1)
        vPow = (1 + interest) ** installments
        actual_interest_rate = (paid_before == 0 ? interest : interest/(1 + interest))
        (vPow * present_value - future_value)/(vPow - 1) * actual_interest_rate
      end
    end


    module FinancialFunctions
      def npv(cashflows, discount_rate)
        (cashflows.enum_for(:each_with_index).collect{|x,i| x/((1+discount_rate)**i)}).inject(0){|a,b| a+b}
      end

      def irr(cash_flows, iterations = 100)
        (1..iterations).inject do |rate,|
          npv = cash_flows.enum_for(:each_with_index).inject {|(m,),(c,t)| m+c/(1.0+rate)**t}
          rate * (1 - npv / cash_flows.first)
        end
      end
    end


    module DmPagination
      class PaginationBuilder
        def url(params)
          @context.params.delete(:action) if @context.params[:action] == 'index'
          @context.url(@context.params.merge(params).reject{|k,v| k=="_message"})
        end
      end
    end


    # Wow. It this supposed to be classless?
    def get_bulk_insert_sql(table_name, data)
      t = Time.now
      keys = data.first.keys.sort_by{|k| k.to_s}
      sql = "INSERT INTO #{table_name}(#{keys.join(',')} )
      VALUES "
      values = []
      classes = data.first.map{|k,v| [k,v.class]}.to_hash
      data.each do |row|
        value = keys.map do |k|
          v = row[k]; c = classes[k]
          raise ArgumentError.new("#{k} is nil") if v.nil?
          # we do not use strftime because gsub is very expensive.
          # SERIOUS ABOUT SCALE baby!
          if c == Date
            "'#{v.year}-#{v.month}-#{v.day}'"
          elsif c == DateTime
            "'#{v.year}-#{v.month}-#{v.day} #{v.hour}:#{v.min}:#{v.sec}'"
          elsif c == String
            "'#{v}'"
          else
            v
          end
        end
        values << "(#{value.join(',')})
        "
      end
      sql += values.join(",") + ";"
      sql
    end

    def get_where_from_hash(hash)
      # naive function to make a WHERE clause from a Hash.
      # isn't there a library somewhere that does this? DM is too slow
      # and additionally, not possible to ask DM to just craft an SQL statement and give it to us (i think)
      hash.map do |col, v|
        if v.class == Date
          val = "'#{v.strftime('%Y-%m-%d')}'"
        elsif v.class == DateTime
          val = "'#{v.strftime('%Y-%m-%d %H:%M:%S')}'"
        elsif v.class == String
          val = "'#{v}'"
        elsif v.class == Array
          val = "(#{v.join(',')})"
        else
          val = v
        end
        v.class == Array ? "#{col} IN #{val}" : "#{col} = #{val}"
      end.join(" AND ")
    end
    
    def q(sql)
      repository.adapter.query(sql)
    end


    class BigDecimal
      def inspect
        self.to_f
      end

      def round_to_nearest(i = nil, style = :round)
        return self if i.nil?
        return self unless self.respond_to?(style)
        (self / i).send(style) * i
      end
    end


    class Nothing
      # instead of saying i.e. (Organization.get_organization(self.received_on).org_guid if Organization.get_organization(self.received_on) or "0000-0000" you can now say
      # (Organization.get_organization(self.received_on) || Nothing).org_guid || "0000-0000"
      def self.method_missing(method_name, *args)
        nil
      end
    end
