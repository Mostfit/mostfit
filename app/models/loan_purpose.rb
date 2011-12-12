class LoanPurpose
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :code, String, :length => 3
  property :parent_id, Integer, :default => 0

  validates_present :name
  validates_is_unique :name
  validates_is_unique :code

  has n, :loans
  # For consistency's sake shouldn't this association be either :children or :loan_purposes?
  has n, :purposes, self, :child_key => [:parent_id]

  default_scope(:default).update(:order => [:name])

  validates_with_method :parent_id, :method => :child_cannot_be_parent

  # This validation checks whether the current record's parent's parent_id refers to the
  # current record (e.g. we are our parent's parent) but what if we go down one more tier?
  # Or we are our own parent? Or...
  def child_cannot_be_parent
    if parent_id == 0
      return true
    else
      pid = LoanPurpose.get(parent_id).parent_id
      if self.id == pid
        return [false, "Cannot be assigned as parent."]
      else
        return true
      end
    end
  end
end
