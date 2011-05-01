class MonthlyTargets < Application
  # provides :xml, :yaml, :js

  def index
    @monthly_targets = MonthlyTarget.all
    display @monthly_targets
  end

  def show(id)
    @monthly_target = MonthlyTarget.get(id)
    raise NotFound unless @monthly_target
    display @monthly_target
  end

  def new
    only_provides :html
    puts "\nMonth was #{params[:month]}"
    @monthly_target = MonthlyTarget.new
    display @monthly_target
  end

  def edit(id)
    only_provides :html
    @monthly_target = MonthlyTarget.get(id)
    raise NotFound unless @monthly_target
    display @monthly_target
  end

  def create(monthly_target)
    @monthly_target = MonthlyTarget.new(monthly_target)
    if @monthly_target.save
      redirect resource(@monthly_target), :message => {:notice => "Monthly Target was successfully set"}
    else
      message[:error] = "Monthly Target was not created"
      render :new
    end
  end

  def update(id, monthly_target)
    @monthly_target = MonthlyTarget.get(id)
    raise NotFound unless @monthly_target
    if @monthly_target.update(monthly_target)
       redirect resource(@monthly_target)
    else
      display @monthly_target, :edit
    end
  end

  def destroy(id)
    @monthly_target = MonthlyTarget.get(id)
    raise NotFound unless @monthly_target
    if @monthly_target.destroy
      redirect resource(:monthly_targets)
    else
      raise InternalServerError
    end
  end

end # MonthlyTargets
