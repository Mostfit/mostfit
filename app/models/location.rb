class Location
  include DataMapper::Resource

  LOCATABLES = ["region", "area", "branch", "center"]

  property :id, Serial
  property :parent_id, Integer, :index => true, :nullable => false
  property :parent_type, Enum.send('[]', *LOCATABLES), :index => true, :nullable => false
  property :latitude,   Float, :index => true, :nullable => false
  property :longitude, Float, :index => true, :nullable => false

  def parent
    Kernel.const_get(self.parent_type.camelcase).get(parent_id)
  end
end
