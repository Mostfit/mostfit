class Branch
  include DataMapper::Resource
  
  property :id,      Serial
  property :name,    String, :length => 100, :nullable => false
  property :address, Text
  

  belongs_to :manager, :class_name => 'StaffMember'
  has n, :centers

end



# # class Branch (models.Model):
# #     """ """
# #     name = models.CharField(max_length=100)
# #     address = models.TextField()
# #     manager = models.ForeignKey(Staff,limit_choices_to={'designation':2})
# #     district = models.ForeignKey(District,null=True,blank=True)
# #     history = audit.AuditTrail(show_in_admin=True)
# #     objects = BranchManager()
# #     
# #     def get_absolute_url (self):
# #         """ """
# #         return "/backoffice/branch/%d"%self.id
# #     
# #     def __str__ (self):
# #         """ """
# #         return self.name
# #     
# #     def center_details (self,days=7,date=date.today()):
# #         """ """
# #         return Center.objects.details(branch=self)
# # 
# #     def staff (self):
# #         """ """
# #         return Staff.objects.filter(center__branch=self).distinct()
# # 
# #     def details (self,days=7,date=date.today()):
# #         """ """
# #         from misfit.financial.models import Loan
# #         details = Loan.objects.details(client__center__branch=self)
# #         details['clients'] = Client.objects.filter(center__branch=self)
# #         at_risk,at_risk_bal = Loan.objects.at_risk(days,now=date,client__center__branch=self)
# #         details['at_risk'] = at_risk_bal
# #         return details