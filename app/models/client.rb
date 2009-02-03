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