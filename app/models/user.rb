class User
  include DataMapper::Resource

  before :destroy, :prevent_destroying_admin

  property :id,           Serial
  property :login,        String, :nullable => false
  property :created_at,   DateTime              
  property :updated_at,   DateTime
  property :active,       Boolean, :default => true, :nullable => false
  # it gets                                   
  #   - :password and :password_confirmation accessors
  #   - :crypted_password and :salt db columns        
  # from the mixin.

  validates_format :login, :with => /^[A-Za-z0-9_]$/
  validates_is_unique :login

  private
  def prevent_destroying_admin
    if id == 1
      errors.add(:login, "Cannot delete #{login} (the admin user).")
      throw :halt
    end                                                             
  end
end
