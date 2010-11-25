class Bookmark
  include DataMapper::Resource
  Types   = [:custom_reports, :other]
  Methods = [:get, :post, :put, :delete]
  ShareWith = [:none, :all, :admin, :staff_member, :mis_manager, :data_entry, :read_only]

  property :id, Serial
  property :name,       String, :length => 50, :nullable => false
  property :title,      String, :length => 100, :nullable => false
  property :route,      Text,   :nullable => false
  property :type,       Enum.send('[]', *Types), :nullable => false,   :default => :other, :index => true
  property :method,     Enum.send('[]', *Methods), :nullable => false, :default => :get, :index => true
  property :params,     Text,    :nullable => true
  property :user_id,    Integer, :nullable => false, :index => true
  property :share_with, Flag.send('[]', *ShareWith), :nullable => false, :default => :none, :index => true
  belongs_to :user
  
  def self.for(user, type=:other)
    {:shared => Bookmark.all(:type => type||:other, :user.not => user).reject{|x| !(x.share_with & [user.role, :all])},  
      :own => Bookmark.all(:user => user, :type => type||:other)}
  end
end
