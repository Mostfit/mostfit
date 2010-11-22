class IncentiveReport < Report
#  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def self.name
    "Incentive Report "
  end

  def generate
       
    data, @hand_over_w,@taken_over_w,@hand_over_m,@taken_over_m = {},{},{},{},{}
    StaffMember.all.to_hash
#    @from_date = Date.new(Date.today.year,Date.today.month,1) 
 #   @to_date = Date.new(Date.today.year,Date.today.month, -1) 
    @from_date = '2009.1.1'
    @to_date = '2010.12.12'
    @from_date_last = Date.new(Date.today.year,Date.today.month-1,1)
    @to_date_last = Date.new(Date.today.year,Date.today.month-1, -1)
    
    
    @net_mgt_w,@net_mgt_m,@d2,@d4,@d15,@d17 = 0,0,0,0,0,0
  
    StaffMember.all(:active => true,:order => [:id.desc]).each_with_index{ |sm, idx|
      data[sm]||={}
      abc = AuditTrail.all(:auditable_type => Center, :action => :update)
      
      abc.each do |x| 
        @center_id = x.auditable_id  
        @updated= x.changes.flatten
        
        for i in 0..(@updated.length - 1)
     
          q = @updated[i].keys.to_s
          if q == "manager_staff_id"
            
            @staff1 = @updated[i].values[0][0] # hand over
            @staff2 = @updated[i].values[0][1] # taken over 
          
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
   
    StaffMember.all(:active => true,:order => [:id.desc]).each_with_index{ |sm, idx|
      data[sm]||={}
   
      data[sm][0] = idx+1
      data[sm][4] = repository.adapter.query("select distinct (a.name) area from clients cl, centers c, staff_members sm,branches b,areas a where cl.center_id = c.id and c.branch_id = b.id and b.area_id = a.id and c.manager_staff_id = sm.id and sm.id = #{sm.id}")
      

      data[sm][6]= data[sm][21] = repository.adapter.query("select count(*) from clients cl,centers c, staff_members sm where cl.date_joined between '#{@from_date}' and '#{@to_date}' and cl.center_id = c.id and cl.deleted_at is NULL and c.manager_staff_id = sm.id and sm.id = #{sm.id}")
     
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
           data[sm][8] = @d2
            
          end

        }
        
        d3 = repository.adapter.query("select count(*) from clients cl,centers c, staff_members sm where cl.date_joined between '#{@from_date_last}' and '#{@to_date_last}' and cl.center_id = c.id and cl.deleted_at is NULL and c.manager_staff_id = sm.id and sm.id = #{sm.id}")[0]

        @hand_over_w.map{|k,v|
          if(k == sm.id)
            @d4 = v[0]
            data[sm][10] = @d4
          end
         
        }
        
        d5 = repository.adapter.query("select count(distinct (l.id)) from loans l ,loan_history lh,staff_members sm where l.id = lh.loan_id and l.installment_frequency = #{lf} and lh.status = 7 and l.disbursed_by_staff_id = #{sm.id} and l.deleted_at is NULL and lh.date between '#{@from_date}' and '#{@to_date}'")[0]
        
        d6 = repository.adapter.query("select count(*) from clients cl,centers c, staff_members sm, loans l where cl.date_joined between '#{@from_date}' and '#{@to_date}' and cl.center_id = c.id and c.manager_staff_id = sm.id and l.client_id = cl.id and sm.id = #{sm.id} and l.installment_frequency = #{lf} and cl.active = false and cl.inactive_reason in (3,4)")[0]

        @taken_over_m.map{|k,v| 
          if (k == sm.id)
            @d15 = v[0]
            data[sm][15] = @d15
          end
        }
        @hand_over_m.map{|k,v|
          if(k == sm.id)
            @d17 = v[0]
            data[sm][17] = @d17
          end
        }
        if lf == 2
          data[sm][7] = d1
          data[sm][9] = d3 
          data[sm][11] = d5
          data[sm][12] = d6
         
          data[sm][13] = data[sm][22] = ((d1[0]+d3[0]+@d2[0]) - (d5[0]+d6[0]+@d4[0]))  
        else
          data[sm][14] = d1
          data[sm][16] = d3
          data[sm][18] = d5
          data[sm][19] = d6
          
          data[sm][20] = data[sm][23] = ((d1[0]+d3[0]+@d15[0]) - (d5[0]+d6[0]+@d17[0]))
        end
      }
    }
    return data
    
  end
end
