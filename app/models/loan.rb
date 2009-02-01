class Loan
  include DataMapper::Resource
  
  property :id,                             Serial
  property :discriminator,                  Discriminator, :nullable => false
  property :amount,                         Integer, :nullable => false  # see helper for formatting
  property :interest_rate,                  Float, :nullable => false
  property :installment_frequency,          Enum[:daily, :weekly, :monthly], :nullable => false
  property :number_of_installments,         Integer, :nullable => false
  property :scheduled_first_payment_date,   Date, :nullable => false  # arbitrary date for installment number 0
  property :scheduled_disbursal_date,       Date, :nullable => false
  property :disbursal_date,                 Date  # not disbursed when nil
  property :created_at,                     DateTime
  property :updated_at,                     DateTime
  property :written_off_on,                 Date

  belongs_to :client
  belongs_to :written_off_by, :child_key => [:written_off_by_staff_id], :class_name => 'StaffMember'
  has n, :payments
  has n, :history, :class_name => 'LoanHistory'


  # TODO: validations!!! (validate written_off_* come/go in pairs)

  def repay(input, user, received_on, received_by)  # TODO: some kind of validation
    # this is the way to repay loans, _not_ directly on the Payment model
    # this to allow validations on the Payment to be implemented in (subclasses of) the Loan

    unless input.is_a? Array or input.is_a? Fixnum
      raise "the input argument of Loan#repay should be of class Fixnum or Array"
    end

    interest, principal, total = 0, 0, 0
    if input.is_a? Fixnum  # in case only one amount is specified
      # interest is paid first, the rest goes in as principal
      total = input.to_i
      interest  = [interest_due_on(received_on), total].min  # just input when not sufficient for interest due 
      principal = total - interest
    elsif input.is_a? Array  # in case principal and interest are specified separately
      principal, interest = input[0].to_i, input[1].to_i
      total = principal + interest
    end

    payment = Payment.new(:loan_id => self.id, :user_id => user.id,
      :received_on => received_on, :received_by_staff_id => received_by,
      :principal => principal, :interest => interest, :total => total)

    [payment.save, payment]  # return the success boolean and the payment object itself for further processing
  end



  def scheduled_principal_for_installment(number)  # typically reimplemented in subclasses
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 0 or number > number_of_installments - 1
    amount.to_f / number_of_installments
  end

  def scheduled_interest_for_installment(number)  # typically reimplemented in subclasses
    # number unused in this implentation, subclasses may decide differently
    # therefor always supply number, so it works for all implementations
    raise "number out of range, got #{number}" if number < 0 or number > number_of_installments - 1
    interest_rate * amount / number_of_installments
  end


  def total_to_be_received
    (self.amount.to_f * (1 + self.interest_rate)).round
  end

  def total_scheduled_principal_on(date)  # typically reimplemented in subclasses
    (amount.to_i / number_of_installments * number_of_installments_before(date)).round
  end
  def total_scheduled_interest_on(date)  # typically reimplemented in subclasses
    (interest_rate * amount / number_of_installments * number_of_installments_before(date)).round
  end
  def total_scheduled_on(date)
    total_scheduled_principal_on(date) + total_scheduled_interest_on(date)
  end

  # next two methods use simple caching
  # it works because objects live short (usualy only within the scope of one request)
  def total_received_principal_on(date)
    return @trp_cache[date] if @trp_cache and @trp_cache[date]
    @trp_cache ||= {}
    @trp_cache[date] = (Payment.sum(:principal, :conditions => ['received_on <= ? AND loan_id = ?', date, self.id]) or 0)
  end
  def total_received_interest_on(date)
    return @tri_cache[date] if @tri_cache and @tri_cache[date]
    @tri_cache ||= {}
    @tri_cache[date] = (Payment.sum(:interest, :conditions => ['received_on <= ? AND loan_id = ?', date, self.id]) or 0)
  end
  def total_received_on(date)
    total_received_principal_on(date) + total_received_interest_on(date)
  end  

  def principle_difference_on(date)
    total_scheduled_principal_on(date) - total_received_principal_on(date)
  end
  def interest_difference_on(date)
    total_scheduled_interest_on(date) - total_received_interest_on(date)
  end
  def total_difference_on(date)
    principle_difference_on(date) + interest_difference_on(date)
  end

  def principal_due_on(date)
    [principle_difference_on(date), 0].max
  end
  def interest_due_on(date)
    [interest_difference_on(date), 0].max
  end
  def total_due_on(date)
    principal_due_on(date) + interest_due_on(date)
  end


  def payment_schedule
    schedule = []
    number_of_installments.times do |number|
      schedule << {
        :date      => shift_date_by_installments(scheduled_first_payment_date, number),
        :principal => scheduled_principal_for_installment(number),
        :interest  => scheduled_interest_for_installment(number) }
    end
    schedule
  end

  def scheduled_payment_dates
    dates = []
    number_of_installments.times do |number|
      dates << shift_date_by_installments(scheduled_first_payment_date, number)
    end
    dates
  end

  def scheduled_payment_date_for_installment(number)
    raise "Loan#scheduled_payment_date_for_installment: number < 1, got #{number}" if number < 1
    if number == 1
      scheduled_first_payment_date
    else
      shift_date_by_installments(scheduled_first_payment_date, number-1)
    end
  end

  def repayment_style
    # how is this loan repayed? principal/interest separate, aggregated or allow either way
    # at some point this should have effect on the view (1 or 2 fields)
    :allow_both   # one of [:separate, :aggregated, :allow_both]
  end

  def written_off?
    not self.written_off_by.blank?
  end

  def status(date = Date.today)
    return :written_off if self.written_off_on and self.written_off_on <= date
    self.total_due_on(date) >= self.total_to_be_received ? :repaid : :outstanding
  end

  def self.loan_stats_for(loans)  # the stats for a collection of loans
    stats = { :outstanding => {:number => 0, :total_amount => 0, :total_repaid => 0, :total_due => 0},
              :repaid =>      {:number => 0, :total_amount => 0},
              :written_off => {:number => 0, :total_amount => 0, :total_repaid => 0} }
    loans.each do |loan|
      s = loan.status
      stats[s][:number]       += 1
      stats[s][:total_amount] += loan.amount
      stats[s][:total_repaid] += loan.total_received_principal_on(Date.today) if [:outstanding, :written_off].include? s
      stats[s][:total_due]    += loan.total_due_on(Date.today) if s == :outstanding
    end
    # calculate percentages
    [:outstanding, :written_off].each do |s|
      p_repaid = stats[s][:total_amount].to_f / stats[s][:total_repaid]
      stats[s][:percentage_repaid] = format("%.2f", p_repaid * 100).to_f
    end
    return stats
  end


  # private
  def number_of_installments_before(date)
    # the number of payment dates before 'date' (if date is a payment 'date' it is counted in)
    return 0 if date < scheduled_first_payment_date
    result = case installment_frequency
      when :daily
      then (date - scheduled_first_payment_date).to_f.floor + 1
      when :weekly
      then ((date - scheduled_first_payment_date).to_f / 7).floor + 1
      when :monthly
      then start_day, start_month = scheduled_first_payment_date.day, scheduled_first_payment_date.month
           end_day, end_month = date.day, date.month
           end_month - start_month + (start_day >= end_day ? 0 : 1)
      else raise "Strange period you got.."
    end
    [result, number_of_installments].min  # never return more than the number_of_installments
  end

  def shift_date_by_installments(date, number)
    raise "Loan#shift_date_by_installments: number < 0, got #{number}" if number < 0
    return date if number == 0
    case installment_frequency
      when :daily
        return date + number
      when :weekly
        return date + number * 7
      when :monthly
        new_month = date.month + number
        new_year  = date.year
        while new_month > 12
          new_year  += 1
          new_month -= 12
        end
        month_lengths = [nil, 31, (Time.gm(new_year, new_month).to_date.leap? ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        new_day = date.day > month_lengths[new_month] ? month_lengths[new_month] : date.day
        return Time.gm(new_year, new_month, new_day).to_date
      else
        raise "Strange period you got.."
    end
  end
end

class A50Loan < Loan
  
end


# # class Loan (models.Model):
# #     client = models.ForeignKey(Client)
# #     loan_type = models.ForeignKey(LoanType)
# #     amount = models.IntegerField()
# #     int_rate = models.FloatField()
# #     date_created = models.DateField(auto_now_add=True)
# #     date_disbursed = models.DateField( null=True,blank=True)
# #     orig_disbursal_date = models.DateField()
# #     orig_schedule = models.ForeignKey(Schedule,blank=True,null=True,editable=False,related_name="orig_schedule")
# #     payment_schedule = models.ForeignKey(Schedule,blank=True,null=True,editable=False)
# #     objects = LoanManager()
# # 
# #     def __set_class__ (self, *args, **kwargs):
# #         """Sets the class of the loan to the loan_type. This is so that overridden methods will work as expected """
# #         try:
# #             if self.loan_type:
# #                 exec "from misfit.financial import %s" % settings.MFI_NAME
# #                 exec ("klass= getattr(%s,'%s')" %(settings.MFI_NAME,self.loan_type.ref))
# #                 if self.__class__ != klass:
# #                     self.__class__ = klass
# #         except:
# #             pass
# # 
# #     def __over_ride__ (self):
# #         """ """
# #         try:
# #             sub = getattr(self,self.loan_type.ref)
# #             overrides = sub.overrides
# #             for o in overrides:
# #                 exec ('self.%s = self.%s.%s' %(o,self.loan_type.ref,o))
# #         except:
# #             pass
# # 
# #     def __reset_class__(self):
# #         """This is required before save to avoid fuckups to do with inheritance """
# #         from misfit.financial import models
# #         self.__class__ = getattr(models,"Loan")
# #         
# #     def get_absolute_url (self):
# #         return reverse('loan_detail',args=[self.id])
# #     
# #     def __unicode__ (self):
# #         return "%d:%s" % (self.id,self.summary())
# # 
# #     def summary (self):
# #         return "Rs. %d @ %f, due %s" %(self.amount, self.int_rate, self.maturity_date())
# # 
# #     def amt_paid (self):
# #         """Calculates the repaid principal amount """
# #         try:
# #             p = self.payment_schedule.payments.extra(select={'sum':'sum(principal)'})[0].sum # convert to sql
# #             return p or 0
# #         except:
# #             return 0
# #         
# #     def os_bal (self):
# #         """Outstanding balance shortcut """
# #         return self.amount - self.amt_paid()
# # 
# #     def is_defaulted (self, days=None, now=date.today()):
# #         ''' Default is_defaulted behaviour'''
# #         ndays = self.loan_type.periodicity_in_days() + 1
# #         days = days or ndays
# #         return  (now-self.last_paid()).days > days 
# #         
# #     def maturity_date (self):
# #         """Over ride this for non standard payment types"""
# #         if self.orig_schedule:
# #             return self.orig_schedule.payments.latest().date
# #         else:
# #             return None
# #     
# #     def last_paid (self):
# #         try:
# #             return self.payment_schedule and self.payment_schedule.payments.filter(principal__gt=0).latest().date
# #         except:
# #             return self.date_disbursed
# # 
# #     def missed_payments (self,date = date.today()):
# #         min_date = self.payment_schedule and self.payment_schedule.payments.filter(principal__gt=0).latest().date or self.date_disbursed
# #         try:
# #             mps = self.orig_schedule.payments.filter(date__gt=min_date,date__lte=date,principal=0)
# #         except:
# #             mps = None
# #         return mps
# # 
# #     def payment_due (self, date=date.today()):
# #         '''Default behaviour: all principal due -  all principal paid. no interest on interest'''
# #         from django.db import connection
# #         paid_sql = 'select sum(principal),sum(interest) from financial_payment fp, financial_schedule_payments fps, financial_schedule fs, financial_loan fl where fp.id = fps.payment_id and fps.schedule_id = fs.id and fl.payment_schedule_id=fs.id and fl.id=%d and fp.date<="%s"' %(self.id,str(date))
# #         cursor = connection.cursor()
# #         r = cursor.execute(paid_sql)
# #         paid = cursor.fetchone()
# #         due_sql = 'select sum(principal),sum(interest) from financial_payment fp, financial_schedule_payments fps, financial_schedule fs, financial_loan fl where fp.id = fps.payment_id and fps.schedule_id = fs.id and fl.orig_schedule_id=fs.id and fl.id=%d and fp.date<="%s"' %(self.id,str(date))
# #         cursor = connection.cursor()
# #         r = cursor.execute(due_sql)
# #         due = cursor.fetchone()
# #         return Payment(principal = (due[0] or 0) - (paid[0] or 0),interest = (due[1] or 0) - (paid[1] or 0)) # should this be max(0,amt) ?
# #         
# #     def disburse (self,today = None):
# #         if today == None:
# #             today = self.orig_disbursal_date
# #         self.date_disbursed = today
# #         self.make_schedule()
# #         self.save()
# # 
# #         
# #     def next_pay_date (self,now):
# #         from datetime import datetime,date
# #         from dateutil.relativedelta import relativedelta
# #         next_pay_date ={
# #             0:now+ relativedelta(days=+1),
# #             1:now + relativedelta(weeks=+1),
# #             2: now + relativedelta(months=+1), }
# #         return next_pay_date.get(self.loan_type.periodicity)
# # 
# #     def fp_date (self):
# #         w = self.orig_disbursal_date + relativedelta.relativedelta(weekday=wd(+1))
# #         return w
# # 
# #     def make_schedule (self):
# #         self.__over_ride__()
# #         s = Schedule()
# #         s.save()
# #         now = self.date_disbursed
# #         for i in range(0,self.loan_type.period):
# #             prin_due = self.prin_payment(i)
# #             int_due = self.int_payment(i)
# #             pmt = prin_due + int_due
# #             ndate = i == 0 and self.fp_date() or self.next_pay_date(now)
# #             now = ndate
# #             p = Payment(num = i+1,date = ndate,principal = prin_due,interest=int_due)
# #             p.save()
# #             s.payments.add(p)
# #         self.orig_schedule = s
# #         ps = Schedule()
# #         ps.save()
# #         self.payment_schedule = ps
# #         if str(type(self)).find('Loan') >= 0:
# #             self.save()
# #     
# #     def pay(self,date,amt):
# #         if amt==0:
# #             raise Exception("No payment was made")
# #         p0 = self.orig_schedule.payments.filter(date__lte=date).latest()
# #         r = amt/(p0.principal + p0.interest)
# #         interest = min(amt,p0.interest*r)
# #         principal = amt - interest
# #         try:
# #             _p = self.payment_schedule.payments.get_or_create(num=p0.num)
# #             raise Exception("this payment has already been made.")
# #         except:
# #             p = self.payment_schedule.payments.create(date=p0.date,principal=principal,interest=interest,num=p0.num)
# # 
# #     def prin_payment (self,period=None):
# #         """Calculates the principal due for the original schedule. Override this in derived classes to modify this behaviour """
# #         return self.amount/self.loan_type.period
# # 
# #     def int_payment (self, period=None):
# #         """Calculates the principal due for the original schedule. Override this in derived classes to modify this behaviour """
# #         return self.amount * self.int_rate / self.loan_type.period
# #         
# #     def cashflow (self):
# #         """Returns the cashflow as an array """
# #         cf = self.orig_schedule.as_array()
# #         act_bal = self.amount
# #         for a in [act_bal,0,0,0]:
# #             cf[0].append(a)
# #         payments = max(self.orig_schedule.payments.count(),self.payment_schedule.payments.count())
# #         for i in range(1,payments+1):
# #             try:
# #                 act = self.payment_schedule.payments.get(num= i)
# #             except:
# #                 act = Payment(principal=0,interest=0)
# #             act_bal = act_bal - act.principal
# #             arr = [act_bal,act.principal,act.interest,act.principal+act.interest]
# #             for a in arr:
# #                 cf[i].append(a)
# #         return cf