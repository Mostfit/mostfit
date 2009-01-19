class Center
  include DataMapper::Resource
  
  property :id,            Serial
  property :name,          String, :length => 100, :nullable => false
  property :meeting_day,   Integer
  property :meeting_time,  Integer

  belongs_to :manager, :class_name => 'StaffMember'
  belongs_to :branch

end


# # class Center (models.Model):
# #     """ """
# #     name = models.CharField(max_length=100)
# #     branch = models.ForeignKey(Branch)
# #     manager = models.ForeignKey(Staff,limit_choices_to={'designation':1})
# #     day_choices = ((1,"Monday"),(2,"Tuesday"),(3,"Wednesday"),(4,"Thursday"),(5,"Friday"),(6,"Saturday"),(7,"Sunday"))
# #     meeting_day = models.IntegerField(choices = day_choices)
# #     meeting_time = models.IntegerField()
# #     objects = CenterManager()
# # 
# #     def get_absolute_url (self):
# #         """ """
# #         return reverse('center_detail', args=[self.id])
# #     
# #     def __str__ (self):
# #         """ """
# #         return self.name
# #     
# #     def next_meeting_date (self, today=date.today()):
# #         """ """
# #         nm = today + relativedelta.relativedelta(weekday=int(self.meeting_day-1))
# #         return nm
# # 
# #     def details (self,days=7,date=date.today()):
# #         """ """
# #         from misfit.financial.models import Loan
# #         details = Loan.objects.details(client__center=self)
# #         at_risk, at_risk_bal = Loan.objects.at_risk(days,now=date,client__center=self)
# #         details['at_risk'] = at_risk_bal 
# #         return details
# # 
# #     def cds (self,date=date.today()):
# #         """ """
# #         from misfit.financial.models import Loan
# #         cl = Loan.objects.filter(client__center=self)
# #         collection = cl.filter(orig_schedule__payments__date=date)
# #         if date.isoweekday() != self.meeting_day:
# #             late = Loan.objects.at_risk(8,now=date,queryset=cl)[0] #The 8 has to be period_days + 1. change this to be more like lastpayment was paid...
# #         else:
# #             late = Loan.objects.get_empty_query_set()
# #         disbursements = Loan.objects.filter(orig_disbursal_date=date,client__center=self,date_disbursed=None)
# #         return {'collection':collection,'disbursements':disbursements,'late':late}