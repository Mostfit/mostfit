class DataAccessObserver
  include DataMapper::Observer
  observe Center, Client, Loan
  
  def self.insert_session(id)
    @_session = ObjectSpace._id2ref(id)
  end

  def self.get_object_state(obj, type)
    #load lazy attributes forcefully here
    @ributes = original_attributes = obj.original_attributes.map{|k,v| {k.name => (k.lazy? ? obj.send(k.name) : v)}}.inject({}){|s,x| s+=x}
    @action = type
  end
  
  def self.log(obj)
    f = File.open("log/#{obj.class}.log","a")
    begin
      if obj
        attributes = obj.attributes
        if @ributes
          diff = @ributes.diff(attributes)
          diff = diff.map{|k| 
            {k => [@ributes[k],attributes[k]]} if k != :updated_at and not (@ributes[k].nil? and attributes[k].class==String and attributes[k].blank?)
          }
          diff=diff.compact
        else
          diff = [attributes.select{|k, v| v and not v.blank? and not v==0}.to_hash]
        end

        if diff.length>0 and diff.find{|x| x.keys.include?(:discriminator)}
          index = diff.index(diff.find{|x| x.keys.include?(:discriminator)})
          diff[index][:discriminator] = diff[index][:discriminator].map{|x| x.to_s if x}
        end
        return if diff.length==0
        model = (/Loan$/.match(obj.class.to_s) ? "Loan" : obj.class.to_s)
        log = AuditTrail.new(:auditable_id => obj.id, :action => @action, :changes => diff.to_yaml, :type => :log,
                             :auditable_type => model, :user => @_session ? @_session.user : User.first)
        log.save
      end
    rescue Exception => e
      p diff if diff
      Merb.logger.info(e.to_s)
      Merb.logger.info(e.backtrace.join("\n"))
    end
  end

  before :create do
    DataAccessObserver.get_object_state(self, :create)
  end  
  
  before :save do
    DataAccessObserver.get_object_state(self, :update) if not self.new?
  end  
  
  after :save do
    DataAccessObserver.log(self)
  end  
    
  before :destroy do
    DataAccessObserver.get_object_state(self, :destroy) if not self.new?
  end

  after :destroy do
    DataAccessObserver.log(self)
  end
end
