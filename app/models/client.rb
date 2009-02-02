class Client
  include DataMapper::Resource
  include Paperclip::Resource
  
  property :id,             Serial
  property :reference,      String, :length => 100, :nullable => false
  property :name,           String, :length => 100, :nullable => false
  property :spouse_name,    String, :length => 100
  property :date_of_birth,  Date
  property :address,        Text

  has_attached_file :picture,
      :styles => {:medium => "300x300>", :thumb => "60x60#"},
      :url => "/uploads/:class/:id/:attachment/:style/:basename.:extension",
      :path => "#{Merb.root}/public/uploads/:class/:id/:attachment/:style/:basename.:extension"

  has_attached_file :application_form,
      :styles => {:medium => "300x300>", :thumb => "60x60#"},
      :url => "/uploads/:class/:id/:attachment/:style/:basename.:extension",
      :path => "#{Merb.root}/public/uploads/:class/:id/:attachment/:style/:basename.:extension"

  has n, :loans
  belongs_to :center

end


# # class Client (models.Model):
# #     name = models.CharField(max_length=50)
# #     husbands_name = models.CharField(max_length=100,null=True,blank=True)
# #     number = models.CharField(max_length=25)
# #     date_of_birth = models.DateField(null=True,blank=True)
# #     address = models.TextField()
# #     ids = models.ManyToManyField(Id)
# # #    approvals = models.ManyToManyField(Approval,editable=False)
# #     center = models.ForeignKey(Center)
# #     pic = models.ImageField(upload_to="files",null=True,blank=True)
# #     app_form = models.ImageField(upload_to="files",null=True,blank=True)
# # 
# #     def details (self,at_risk_days=None,now=date.today()):
# #         """ """
# #         from misfit.financial.models import Loan
# #         loans = Loan.objects.details(client=self,at_risk_days=at_risk_days,now=now)
# #         return loans
# #         
# #         
# #     def is_approved (self):
# #         return len(self.approvals)>2
# #     def __str__ (self):
# #         """ """
# #         return "%s" %(self.name)
# #     def get_absolute_url (self):
# #         """ """
# #         return reverse('client_detail', args=[self.id])

