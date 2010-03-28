module DataMapper
  module Stamped
    module Stamper
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        def current_user=(user)
          Thread.current["#{self.to_s.downcase}_#{self.object_id}_stamper"] = user
        end

        def current_user
          Thread.current["#{self.to_s.downcase}_#{self.object_id}_stamper"]
        end
      end
    end
    
    def self.included(model)
      return if model.name == 'ActionLog'
      #model.after :create do _log(:create); end
      #model.after :update do _log(:update); end
      #model.before :destroy do _log(:destroy); end
      #model.extend ClassMethods
    end

    
    def _log(action)
      puts "logging"
      log = {
        :action => action,
        :klass => self.class,
        :record => self.id,
        :user_id => 1
      }
      #::ActionLog.create(log).errors
      @a = ::ActionLog.new(log)
      @a.inspect
      @a.save
      return @a
    end


    module ClassMethods
      
      def created_by
        ActionLog.first({
                          :action => :create,
                          :klass => self.class,
                          :record => self.id
                        }).user
      end

      def updated_by
        ActionLog.first({
                          :action => :update,
                          :klass => self.class,
                          :record => self.id
                        }, :order => [:time.desc]).user
      end
      
      def deleted_by
        ActionLog.first({
                          :action => :destroy,
                          :klass => self.class,
                          :record => self.id
                        }, :order => [:time.desc]).user
      end
      
    end # module ClassMethods
    
    
  end # module Stamped
  
  Model::append_inclusions Stamped
  
end # module DataMapper

class ActionLog
  include DataMapper::Resource

  property :id, Serial
  property :action,               String, :length => 20, :required => true
  property :klass,                String, :length => 50, :required => true
  property :record,               String, :length => 30, :required => true
  property :time,                 DateTime, :default => Proc.new { |r,p| Time.now }, :writer => :private

  belongs_to :user
end


