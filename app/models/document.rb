class Document
  include DataMapper::Resource
  include Paperclip::Resource
  
  property :id, Serial
  property :date_of_issue, Date, :index => true
  property :valid_upto, Date, :index => true
  property :number, String, :index => true
  property :issuing_authority, String, :index => true

  property :parent_model, Enum.send('[]', *ModelsWithDocuments), :index => true
  property :parent_id, Integer, :index => true
  property :document_type_id, Integer, :index => true
  property :description, Text, :nullable => true
  
  belongs_to :document_type  
  has_attached_file :document,
      :url => "/uploads/:class/:id/:basename.:extension",
      :path => "#{Merb.root}/public/uploads/:class/:id/:basename.:extension" 
  has_attached_file :document_2,
      :url => "/uploads/:class/:id/2/:basename.:extension",
      :path => "#{Merb.root}/public/uploads/:class/:id/2/:basename.:extension" 
  has_attached_file :document_3,
      :url => "/uploads/:class/:id/3/:basename.:extension",
      :path => "#{Merb.root}/public/uploads/:class/:id/3/:basename.:extension" 
  has_attached_file :document_4,
      :url => "/uploads/:class/:id/4/:basename.:extension",
      :path => "#{Merb.root}/public/uploads/:class/:id/4/:basename.:extension" 

  validates_present :document_type
  validates_is_unique :number, :scope => [:document_type_id, :parent_id, :parent_model]

  def parent
    Kernel.const_get(parent_model).get(parent_id)
  end
end
