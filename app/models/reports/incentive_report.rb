class IncentiveReport < Report
#  attr_accessor :from_date, :to_date
  def initialize(start_date)  
    self.start_date = (start_date.is_a? Date) ? start_date : Date.parse(start_date)
    self.end_date   = Date.new(Date.today.year,Date.today.month, -1).strftime('%Y-%m-%d')
    @name = "Incentive report"
  end
 
  def name
    "Month starting #{self.start_date} upto #{self.end_date}"
  end

  def to_str
    "#{self.start_date} - #{self.end_date}"
  end

  def loan_count_by_frequency_and_cm_change(loan_frequency, old_cm, new_cm, center_id, from_date, to_date)
    loan_count = repository.adapter.query(%Q{
                 SELECT count(distinct(l.id))
                 FROM loans l,clients cl, centers c, staff_members sm
                 WHERE l.disbursal_date between '#{from_date}' AND '#{to_date}'
                       AND l.installment_frequency = #{loan_frequency} AND l.disbursed_by_staff_id = #{old_cm}
                       AND l.deleted_at is NULL AND cl.deleted_at is NULL AND l.client_id = cl.id
                       AND cl.center_id = c.id AND c.id = #{center_id} AND c.manager_staff_id = #{new_cm}})
  end

  def staff_member_work_area(sm)
    staff_area = repository.adapter.query(%Q{
                           SELECT distinct (b.name)
                           FROM clients cl, centers c, staff_members sm,branches b
                           WHERE cl.center_id = c.id AND c.branch_id = b.id
                                 AND c.manager_staff_id = sm.id AND sm.id = #{sm.id}})
  end

  def new_client_count_current_month(sm, from_date, to_date)
    new_client_count = repository.adapter.query(%Q{
                            SELECT count(*)
                            FROM clients cl,centers c, staff_members sm
                            WHERE cl.date_joined BETWEEN '#{from_date}' AND '#{to_date}'
                                  AND cl.center_id = c.id AND cl.deleted_at is NULL
                                  AND c.manager_staff_id = sm.id AND sm.id = #{sm.id}})
  end

  def new_loan_count_current_month(sm,loan_frequency,from_date, to_date)
    new_loan_count = repository.adapter.query(%Q{
                           SELECT count(distinct(l.id))
                           FROM loans l,staff_members sm
                           WHERE l.disbursal_date BETWEEN '#{from_date}' AND '#{to_date}'
                                 AND l.installment_frequency = #{loan_frequency}
                                 AND l.disbursed_by_staff_id = #{sm.id} AND l.deleted_at is NULL})
  end

  def closed_loan_count_current_month(sm,loan_frequency,from_date, to_date)
    closed_loan_count = repository.adapter.query(%Q{
                           SELECT count(distinct (l.id))
                           FROM loans l ,loan_history lh,staff_members sm
                           WHERE l.id = lh.loan_id AND l.installment_frequency = #{loan_frequency}
                              AND lh.status = 7 AND l.disbursed_by_staff_id = #{sm.id}
                              AND l.deleted_at is NULL AND lh.date between '#{from_date}' AND '#{to_date}'})
  end

  def death_cases_current_month(sm,loan_frequency,from_date, to_date)
    death_count = repository.adapter.query(%Q{
                           SELECT count(*)
                           FROM clients cl,centers c, staff_members sm, loans l
                           WHERE cl.date_joined BETWEEN '#{from_date}' AND '#{to_date}'
                              AND cl.center_id = c.id AND c.manager_staff_id = sm.id AND l.client_id = cl.id
                              AND sm.id = #{sm.id} AND l.installment_frequency = #{loan_frequency}
                              AND cl.active = false AND cl.inactive_reason IN (3,4)})
  end

  def previous_month_client_count_by_loan_frequency(sm,loan_frequency,from_date_last,to_date_last)
    pre_month_client_count = repository.adapter.query(%Q{
                               SELECT count(*)
                               FROM clients cl, centers c, loans l, staff_members sm
                               WHERE cl.date_joined BETWEEN '#{from_date_last}' AND '#{to_date_last}'
                                     AND cl.center_id = c.id AND cl.deleted_at is NULL
                                     AND l.client_id = cl.id AND l.installment_frequency = #{loan_frequency}
                                     AND l.disbursal_date BETWEEN '#{from_date_last}' AND '#{to_date_last}'
                                     AND l.disbursed_by_staff_id = #{sm.id} AND l.deleted_at is NULL
                                     AND c.manager_staff_id = sm.id AND sm.id = #{sm.id}})
  end

  def center_change_details_for_cm(from_date,to_date)
    @report,@hand_over_w,@taken_over_w,@hand_over_m,@taken_over_m = {},{},{},{},{}
    StaffMember.all(:active => true,:order => [:id.desc]).each{ |sm|
      @report[sm]||={}
        
      AuditTrail.all(:auditable_type => Center, :action => :update).each do |trail| 
        center_id = trail.auditable_id
        data= trail.changes.flatten

        0.upto(data.length - 1).each do |change|
          if data[change].keys.to_s == "manager_staff_id"    
            staff1= data[change].values[0][0] # hand over
            staff2 = data[change].values[0][1] # taken over 
            change_date = trail.created_at.strftime("%Y-%m-%d")
            center = @centers[center_id]
            next unless center
            if (sm.id == staff2)
              @report[sm][3] = "Transfered to Center #{center.name} on #{change_date.to_s}"
            elsif (sm.id == staff1)
              @report[sm][5] = "Released from Center #{center.name} on #{change_date.to_s}"
            end

            if staff1== sm.id
              1.upto(2){|x|
                if x == 1 
                  loan_frequency = INSTALLMENT_FREQUENCIES.index(:weekly)+1
                else
                  loan_frequency = INSTALLMENT_FREQUENCIES.index(:monthly)+1
                end
   
                loan_count = loan_count_by_frequency_and_cm_change(loan_frequency, staff1, staff2, center_id, from_date, to_date)
                
                @hand_over_w[@staff]||={}
                @taken_over_w[@staff]||={}
                @hand_over_m[@staff]||={}
                @taken_over_m[@staff]||={}
                
                if loan_frequency == INSTALLMENT_FREQUENCIES.index(:weekly)+1
                  @hand_over_w[staff2] = loan_count
                  @taken_over_w.map{ |k,v|     
                    if staff1 == k
                      @taken_over_w[staff1] = loan_count[0] + v[0] 
                    else
                      @taken_over_w[staff1] = loan_count
                    end
                  }  
                else
                  @taken_over_m.map{ |k,v|     
                    if staff1 == k
                      @taken_over_m[staff1] = loan_count[0] + v[0]  
                    else
                      @taken_over_m[staff1] = loan_count
                    end
                  }
                  @hand_over_m[staff2] = loan_count
                end
              }
            end
          end
        end
      end
      
    }
  end

  def calc
    t0 = Time.now
    @centers =  Center.all.map{|c| [c.id, c]}.to_hash
    from_date = Date.new(Date.today.year,Date.today.month,1).strftime('%Y-%m-%d') 
    to_date = Date.new(Date.today.year,Date.today.month, -1).strftime('%Y-%m-%d') 

    from_date_last = Date.new(Date.today.year,Date.today.month-1,1).strftime('%Y-%m-%d')
    to_date_last = Date.new(Date.today.year,Date.today.month-1, -1).strftime('%Y-%m-%d')
    
    d2,d4,d15,d17 = 0,0,0,0
    
    center_change_details_for_cm(from_date,to_date)
   
    StaffMember.all(:active => true,:order => [:id.desc]).each{ |sm|
      @report[sm][4] = staff_member_work_area(sm)
      @report[sm][6]= @report[sm][21] = new_client_count_current_month(sm,from_date,to_date)
          
      1.upto(2){ |x|
        if x == 1 
          loan_frequency = INSTALLMENT_FREQUENCIES.index(:weekly)+1
        else
          loan_frequency = INSTALLMENT_FREQUENCIES.index(:monthly)+1
        end

        d1 = new_loan_count_current_month(sm,loan_frequency,from_date, to_date)
        @taken_over_w.map{|k,v| 
          if (k == sm.id)
            d2 = v
            @report[sm][8] = d2
          end
        }
        
        d3 = previous_month_client_count_by_loan_frequency(sm,loan_frequency,from_date_last,to_date_last)
        @hand_over_w.map{|k,v|
          if(k == sm.id)
            d4 = v
            @report[sm][10] = d4
          end
        }
        
        d5 = closed_loan_count_current_month(sm,loan_frequency,from_date, to_date)
        
        d6 =  death_cases_current_month(sm,loan_frequency,from_date, to_date)

        @taken_over_m.map{|k,v| 
          if (k == sm.id)
            d15 = v
            @report[sm][15] = d15
          end
        }
        @hand_over_m.map{|k,v|
          if(k == sm.id)
            d17 = v
            @report[sm][17] = d17
          end
        }
        if loan_frequency == INSTALLMENT_FREQUENCIES.index(:weekly)+1
          @report[sm][7] = d1
          @report[sm][9] = d3 
          @report[sm][11] = d5
          @report[sm][12] = d6
          
          @report[sm][13] = @report[sm][22] = ((d1[0]+d3[0]+d2[0]) - (d5[0]+d6[0]+d4[0])).abs
        else
          @report[sm][14] = d1
          @report[sm][16] = d3
          @report[sm][18] = d5
          @report[sm][19] = d6
          
          @report[sm][20] = @report[sm][23] = ((d1[0]+d3[0]+d15[0]) - (d5[0]+d6[0]+d17[0])).abs
        end
      }
    }
   
    IncentiveReport.all(:start_date => from_date, :end_date =>to_date).destroy!
    self.raw = @report
    self.report = Marshal.dump(@report)
    self.generation_time = Time.now - t0
    self.save
  end
end
