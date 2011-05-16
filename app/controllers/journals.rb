class Journals < Application
  include DateParser
  before :get_context

  # provides :xml, :yaml, :js
  def index
    hash = {:order => [:created_at.desc]}
    hash[:date.gte] = params[:from_date] || Date.today
    hash[:date.lte] = params[:to_date] || Date.today
    hash[:journal_type_id] = params[:journal_type_id] if params[:journal_type_id] and not params[:journal_type_id].blank?
 
    @journals = Journal.all(hash).paginate(:per_page => 20, :page => params[:page] ||1 )
    display @journals, :layout => layout?
  end

  def new
    only_provides :html
    @journal = Journal.new
    display @journal, :layout => layout?
  end

  def show(id)
    @journal = Journal.get(id)
    raise NotFound unless @journal
    display @journal
  end


  def add_account
    partial :account_amount, :layout => layout?, :last_account => true, :account_type => (params[:account_type]||"credit_account").to_sym, :account => {}
  end

  def create(journal)
    @branch  = Branch.get(params[:branch_id]) if params[:branch_id]

    if params[:debit_account] and params[:credit_account]
      #single debit and single credit accounts
      debit_accounts  = Account.get(params[:debit_account][:account_id])
      credit_accounts = Account.get(params[:credit_account][:account_id])
    elsif params[:debit_accounts] and params[:credit_accounts]
      #multiple debit and credit accounts
      debit_accounts, credit_accounts  = {}, {}
      params[:debit_accounts].each{|debit|
        debit_accounts[Account.get(debit[:account_id])] = debit[:amount].to_i
      }
      params[:credit_accounts].each{|credit|
        credit_accounts[Account.get(credit[:account_id])] = credit[:amount].to_i      
      }
    end

    journal[:currency] = Currency.first
    status, @journal = Journal.create_transaction(journal, debit_accounts, credit_accounts)

    if status
      if params[:return] and not params[:return].blank?
        redirect params[:return], :message => {:notice => "Journal was successfully created"}        
      elsif @branch
        redirect resource(@branch), :message => {:notice => "Journal was successfully created"}
      else
        redirect resource(:accounts)+"#journal_entries", :message => {:notice => "Journal was successfully created"}
      end
    else
      message[:error] = "Journal failed to be created"
      render :new
    end
  end

  def edit(id)
    only_provides :html
    @journal = Journal.get(id)
    raise NotFound unless @journal
    display @journal, :layout => layout?
  end

  def update(id, journal)
    @journal = Journal.get(id)
    raise NotFound unless @journal
    if @journal.update_attributes(journal)
      redirect resource(:journals), :message => {:notice => "Journal was successfully edited"}
    else
      message[:error] = "Journal could not be edited"
      redirect resource(:journals)
    end
  end

  # Action for EOD voucher entry
  def new_eod
    @branch = Branch.get(params[:branch_id])
    raise BadRequest unless @branch
    @date = Date.parse(params[:date])
    @journal = Journal.new
    @rules = RuleBook.all(:branch => @branch, :from_date.lte => @date, :to_date.gte => @date)
    render :new_eod, :layout => layout?
  end

  # Action for creatng EOD voucher entry
  def create_eod(journal)
    @branch  = Branch.get(params[:branch_id]) if params[:branch_id]

    if params[:debit_accounts] and params[:credit_accounts]
      #multiple debit and credit accounts
      debit_accounts, credit_accounts  = {}, {}
      
      params[:debit_accounts].group_by{|x| x[:journal_type_id]}.each{|jid, debits|
        debit_accounts[jid] ||= {}
        debits.each{|debit|
          debit_accounts[jid][Account.get(debit[:account_id])] ||= 0
          debit_accounts[jid][Account.get(debit[:account_id])] += debit[:amount].to_i
        }
      }

      params[:credit_accounts].group_by{|x| x[:journal_type_id]}.each{|jid, credits|
        credit_accounts[jid] ||= {}
        credits.each{|credit|
          credit_accounts[jid][Account.get(credit[:account_id])] ||= 0
          credit_accounts[jid][Account.get(credit[:account_id])] += credit[:amount].to_i
        }
      }

      # get the uniq journal types
      journal_types = debit_accounts.keys
    else
      raise BadRequest
    end

    statuses, journals = [], []

    journal_types.each{|journal_type|
      # reject accounts where amounts are zero
      debit_accounts[journal_type]  = debit_accounts[journal_type].reject{|k, v| v == 0}
      credit_accounts[journal_type] = credit_accounts[journal_type].reject{|k, v| v == 0}

      journal[:journal_type_id] = journal_type.to_i
      journal[:currency] = Currency.first

      status, journal_obj = Journal.create_transaction(journal, debit_accounts[journal_type], credit_accounts[journal_type])
      statuses.push(status)
      journals.push(journal_obj)
    }

    if not statuses.include?(false)
      if params[:return] and not params[:return].blank?        
        return_path =  params[:return]
      elsif @branch
        return_path = resource(@branch)
      else
        return_path =  resource(:accounts)+"#journal_entries"
      end
      
      if request.xhr?
        render "Journal was successfully created", :layout => layout?
      else
        redirect return_path, :message => {:notice => "Journal was successfully created"}
      end
    else
      message[:error] = ""
      statuses.each_with_index{|status, i|
        unless status
          if journals[i] and journals[i].journal_type
            message[:error] += "#{journals[i].journal_type.name} journal failed to be created"
          else
            message[:error] += "Journal failed to be created because #{journals[i].errors.to_s}"
          end
        end
      }
      render :new, :layout => layout?
    end
  end
  
  def reconcile
    if params[:branch_id] and not params[:branch_id].blank?

      if params[:branch_id] == "0"
        @branch = Branch.all
      else
        @branch = Branch.all(:id => params[:branch_id])
      end

      raise BadRequest unless @branch.length > 0

      @from_date = Date.parse(params[:from_date])
      @to_date = Date.parse(params[:to_date])
      
      # get all the relevant rules
      @rules = RuleBook.all(:branch => @branch, :from_date.lte => @to_date, :to_date.gte => @to_date).group_by{|x| x.action.to_sym}
      
      # get all the relevant figures from the loan system
      @disbursement = Loan.all("client.center.branch_id" => @branch.map{|b| b.id}, :disbursal_date.gte => @from_date, 
                               :disbursal_date.lte => @to_date, :rejected_on => nil).aggregate(:amount.sum)
      @principal    = Payment.all("client.center.branch_id" => @branch.map{|b| b.id}, :received_on.gte => @from_date, 
                                  :received_on.lte => @to_date, :type => :principal).aggregate(:amount.sum) || 0
      @interest     = Payment.all("client.center.branch_id" => @branch.map{|b| b.id}, :received_on.gte => @from_date,
                                  :received_on.lte => @to_date, :type => :interest).aggregate(:amount.sum) || 0
      @fees         = (Payment.all("client.center.branch_id" => @branch.map{|b| b.id}, :received_on.gte => @from_date,
                                  :received_on.lte => @to_date, :type => :fees).aggregate(:fee_id, :amount.sum) || []).to_hash
    end
    render :layout => layout?
  end

  def tally_download
    if params[:from_date] and params[:to_date]
      from_date = Date.parse(params[:from_date])
      to_date   = Date.parse(params[:to_date])

      file   = File.join("/", "tmp", "voucher_#{from_date.strftime('%Y-%m-%d')}_#{to_date.strftime('%Y-%m-%d')}_#{Time.now.to_i}.xml")
      Journal.xml_tally({:date.gte => from_date, :date.lte => to_date}, file)
      send_data(File.read(file), :filename => file)
    else
      render :layout => layout?
    end
  end

  private
  def get_context
    @branch       = Branch.get(params[:branch_id]) if params[:branch_id] and params[:branch_id].to_i > 0
  end
end # Journals
