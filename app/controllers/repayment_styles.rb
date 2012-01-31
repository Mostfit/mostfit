class RepaymentStyles < Application
  # provides :xml, :yaml, :js

  def index
    @repayment_styles = RepaymentStyle.all
    display @repayment_styles
  end

  def show(id)
    @repayment_style = RepaymentStyle.get(id)
    raise NotFound unless @repayment_style
    display @repayment_style
  end

  def new
    only_provides :html
    @repayment_style = RepaymentStyle.new
    display @repayment_style
  end

  def edit(id)
    only_provides :html
    @repayment_style = RepaymentStyle.get(id)
    raise NotFound unless @repayment_style
    display @repayment_style
  end

  def create(repayment_style)
    @repayment_style = RepaymentStyle.new(repayment_style)
    if @repayment_style.save
      redirect resource(:repayment_styles), :message => {:notice => "RepaymentStyle was successfully created"}
    else
      message[:error] = "RepaymentStyle failed to be created"
      render :new
    end
  end

  def update(id, repayment_style)
    @repayment_style = RepaymentStyle.get(id)
    raise NotFound unless @repayment_style
    if @repayment_style.update(repayment_style) || @repayment_style.errors.blank?
      redirect resource(@repayment_style), :message => {:notice => "RepaymentStyle : #{@repayment_style.name} was successfully updated"}
    else
      display @repayment_style, :edit
    end
  end

  def destroy(id)
    @repayment_style = RepaymentStyle.get(id)
    raise NotFound unless @repayment_style
    if @repayment_style.destroy
      redirect resource(:repayment_styles)
    else
      raise InternalServerError
    end
  end

end # RepaymentStyles
