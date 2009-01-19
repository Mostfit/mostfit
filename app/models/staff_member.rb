class StaffMember
  include DataMapper::Resource
  
  property :id,      Serial
  property :name,    String, :length => 100, :nullable => false
  property :active,  Boolean, :default => true, :nullable => false
  # no designations, they are derived from the relations it has

  has n, :centers
  has n, :branches

  validates_is_unique :name


end



# # class Staff (Person):
# #     """ """
# #     choices = ((0,"Loan Officer"),(1,"Center Manager"),(2,"Branch Manager"),(3,"District Manager"),(4,"MIS Manager"))
# #     designation = models.IntegerField(choices=choices)
# #     history = audit.AuditTrail(show_in_admin=True)
# #     def __str__ (self):
# #         """ """
# #         return self.name
# # 
# #     def get_absolute_url (self):
# #         """ """
# #         from django.core.urlresolvers import reverse
# #         return reverse('staff_detail',args=[self.id])
# # 
# #     def loan_details (self):
# #         """ """
# #         details = Loan.objects.details(client__center__manager=self)
# #         return details
# # 
# #     def center_details (self):
# #         """ """
# #         if self.designation == 2:
# #             return Center.objects.details(branch__manager=self)
# #         return Center.objects.details(manager=self)
# # 
# #     def loan_details (self):
# #         """ """
# #         from misfit.financial.models import Loan
# #         if self.designation == 2:
# #             return Loan.objects.details(client__center__branch__manager=self)
# #         return Loan.objects.details(client__center__manager=self)