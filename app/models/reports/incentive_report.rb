class IncentiveReport < Report
#  attr_accessor :from_date, :to_date
  def initialize(start_date)                                                                                   
  
    self.start_date = (start_date.is_a? Date) ? start_date : Date.parse(start_date)                            
    self.end_date   = Date.new(Date.today.year,Date.today.month, -1).strftime('%Y-%m-%d')
    @name = "Incentive report"                                                             
  end                                                                                                         
 
  def name                                                                                                     
    "month starting #{self.start_date} upto #{self.end_date}"
  end
                                                                                                          
  def to_str                                                                                                   
    "#{self.start_date} - #{self.end_date}"                                                                    
  end                          
 
  def calc
    t0 = Time.now
    @report, @hand_over_w,@taken_over_w,@hand_over_m,@taken_over_m = {},{},{},{},{}
    StaffMember.all.to_hash
    @from_date = Date.new(Date.today.year,Date.today.month,1).strftime('%Y-%m-%d') 
    @to_date = Date.new(Date.today.year,Date.today.month, -1).strftime('%Y-%m-%d') 

    @from_date_last = Date.new(Date.today.year,Date.today.month-1,1).strftime('%Y-%m-%d')
    @to_date_last = Date.new(Date.today.year,Date.today.month-1, -1).strftime('%Y-%m-%d')
    
    @net_mgt_w,@net_mgt_m,@d2,@d4,@d15,@d17 = 0,0,0,0,0,0
    
    StaffMember.all(:active => true,:order => [:id.desc]).each_with_index{ |sm, idx|
      @report[sm]||={}
      
      center_changes = AuditTrail.all(:auditable_type => Center, :action => :update)
      
      center_changes.each do |trail| 
        @center_id = trail.auditable_id  
        @updated= trail.changes.flatten
        
        for i in 0..(@updated.length - 1)
          
          q = @updated[i].keys.to_s
          if q == "manager_staff_id"
            
            @staff1 = @updated[i].values[0][0] # hand over
            @staff2 = @updated[i].values[0][1] # taken over 
            change_date = trail.created_at.strftime("%Y-%m-%d")
            if (sm.id == @staff2)
              @c = Center.get(@center_id)              
              @report[sm][3] = "Transfered to Center #{@c.name} on #{change_date.to_s}"
            elsif (sm.id == @staff1)
              @report[sm][5] = "Released from Center #{@c.name} on #{change_date.to_s}"
            end

            if @staff1 == sm.id
              1.upto(2){|x|
                if x == 1 
                  @lf = 2
                else
                  @lf = 4
                end
                loan_count = repository.adapter.query("select count(distinct(l.id)) from loans l,clients cl, centers c, staff_members sm where l.disbursal_date between '#{@from_date}' and '#{@to_date}' and l.installment_frequency = #{@lf} and l.disbursed_by_staff_id = #{@staff1} and l.deleted_at is NULL and cl.deleted_at is NULL and l.client_id = cl.id and cl.center_id = c.id and c.id = #{@center_id} and c.manager_staff_id = #{@staff2}")          
                if @lf == 2
                  @hand_over_w[@staff]||={}
                  @taken_over_w[@staff]||={}
                  @hand_over_w[@staff2] = loan_count
                  @taken_over_w.map{ |k,v|     
                    if @staff1 == k
                      @taken_over_w[@staff1] = v
                    else
                      @taken_over_w[@staff1] = loan_count
                    end
                  }
                  
                else
                  @hand_over_m[@staff]||={}
                  @taken_over_m[@staff]||={}
                  @taken_over_m.map{ |k,v|     
                    if @staff1 == k
                      @taken_over_m[@staff1] = v 
                    else
                      @taken_over_m[@staff1] = loan_count
                    end
                  }
                  @hand_over_m[@staff2] = loan_count
                end
              }
            end
          end
        end
      end
      
    }
    
    StaffMember.all(:active => true,:order => [:id.desc]).each{ |sm|
          
      @report[sm][4] = repository.adapter.query("select distinct (b.name) area from clients cl, centers c, staff_members sm,branches b where cl.center_id = c.id and c.branch_id = b.id and c.manager_staff_id = sm.id and sm.id = #{sm.id}")
      
      @report[sm][6]= @report[sm][21] = repository.adapter.query("select count(*) from clients cl,centers c, staff_members sm where cl.date_joined between '#{@from_date}' and '#{@to_date}' and cl.center_id = c.id and cl.deleted_at is NULL and c.manager_staff_id = sm.id and sm.id = #{sm.id}")
      
      1.upto(2){ |x|
        if x == 1 
          lf = 2
        else
          lf = 4
        end
        d1 = repository.adapter.query("select count(distinct(l.id)) from loans l,staff_members sm where l.disbursal_date between '#{@from_date}' and '#{@to_date}' and l.installment_frequency = #{lf} and l.disbursed_by_staff_id = #{sm.id} and l.deleted_at is NULL")
        
        @taken_over_w.map{|k,v| 
          if (k == sm.id)
            @d2 = v[0]
            @report[sm][8] = @d2
          end
        }
        
        d3 = repository.adapter.query("select count(*) from clients cl,centers c, staff_members sm where cl.date_joined between '#{@from_date_last}' and '#{@to_date_last}' and cl.center_id = c.id and cl.deleted_at is NULL and c.manager_staff_id = sm.id and sm.id = #{sm.id}")[0]

        @hand_over_w.map{|k,v|
          if(k == sm.id)
            @d4 = v[0]
            @report[sm][10] = @d4
          end
        }
        
        d5 = repository.adapter.query("select count(distinct (l.id)) from loans l ,loan_history lh,staff_members sm where l.id = lh.loan_id and l.installment_frequency = #{lf} and lh.status = 7 and l.disbursed_by_staff_id = #{sm.id} and l.deleted_at is NULL and lh.date between '#{@from_date}' and '#{@to_date}'")[0]
        
        d6 = repository.adapter.query("select count(*) from clients cl,centers c, staff_members sm, loans l where cl.date_joined between '#{@from_date}' and '#{@to_date}' and cl.center_id = c.id and c.manager_staff_id = sm.id and l.client_id = cl.id and sm.id = #{sm.id} and l.installment_frequency = #{lf} and cl.active = false and cl.inactive_reason in (3,4)")[0]

        @taken_over_m.map{|k,v| 
          if (k == sm.id)
            @d15 = v[0]
            @report[sm][15] = @d15
          end
        }
        @hand_over_m.map{|k,v|
          if(k == sm.id)
            @d17 = v[0]
            @report[sm][17] = @d17
          end
        }
        if lf == 2
          @report[sm][7] = d1
          @report[sm][9] = d3 
          @report[sm][11] = d5
          @report[sm][12] = d6
          
          @report[sm][13] = @report[sm][22] = ((d1[0]+d3[0]+@d2[0]) - (d5[0]+d6[0]+@d4[0])).abs
        else
          @report[sm][14] = d1
          @report[sm][16] = d3
          @report[sm][18] = d5
          @report[sm][19] = d6
          
          @report[sm][20] = @report[sm][23] = ((d1[0]+d3[0]+@d15[0]) - (d5[0]+d6[0]+@d17[0])).abs
        end
      }
    }
    
    
    IncentiveReport.all(:start_date => @from_date, :end_date =>@to_date).destroy!
    self.raw = @report
    self.report = Marshal.dump(@report)
    self.generation_time = Time.now - t0
    self.save
  end
end
