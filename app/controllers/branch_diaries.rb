class BranchDiaries < Application
  before :get_context, :exclude => ['redirect_to_show']
  provides :xml, :yaml, :js
  include DateParser

  def index
    if request.xhr? and params[:branch_id]
      @branch_diaries = BranchDiary.all(:branch_id => params[:branch_id]).paginate(:page => params[:page], :per_page => 15, :order => [:diary_date.desc])
      display @branch_diaries, :layout => layout?
    else
      @branch_diaries = (@branch_diaries || BranchDiary.all).paginate(:page => params[:page], :per_page => 15)
      display @branch_diaries, :layout => layout?
    end
  end

  def show(id)
    @branch_diary = BranchDiary.get(id)
    raise NotFound unless @branch_diary
    display @branch_diary , :layout => layout?
  end

  def new
    only_provides :html
    @branch_diary = BranchDiary.new
    @branch = Branch.get(params[:branch_id]) if params and params.key?(:branch_id)
    display @branch_diary, :layout => layout?
  end

  def edit(id)
    only_provides :html
    @branch_diary = BranchDiary.get(id)
    raise NotFound unless @branch_diary
    @branch = @branch_diary.branch if @branch_diary.branch_id
    display @branch_diary, :layout => layout?
  end

  def create(branch_diary)
    @branch_diary = BranchDiary.new(branch_diary)
    if @branch_diary.save
      redirect(params[:return] ||resource(@branch_diary.branch), :message => {:notice => "Diary entry was successfully entered"})
    else
      message[:error] = "BranchDiary failed to be entered"
      render :new  # error messages will show
    end
  end

  def update(id, branch_diary)
    @branch_diary = BranchDiary.get(id)
    raise NotFound unless @branch_diary
    if @branch_diary.update(branch_diary)
      redirect(params[:return] || resource(@branch_diary.branch), :message => {:notice => "Diary entry was successfully updated."})
    else
      display @branch_diary, :edit  #error messages will show
    end
  end

  def branch
    @branch_diary = BranchDiary.new
    render :layout => layout?
  end

  def destroy(id)
    @branch_diary = BranchDiary.get(id)
    raise NotFound unless @branch_diary
    if @branch_diary.destroy
      redirect resource(:branch_diaries), :message => {:notice => "Details was successfully deleted"} 
    else
      raise InternalServerError
    end
  end

  def delete(id)
    edit(id)
  end

  def redirect_to_show(id)
    raise NotFound unless @branch_diary = BranchDiary.get(id)
    redirect resource(@branch_diary)
  end

  private
  def get_context
    @branch = Branch.get(params[:branch_id]) if params.key?(:branch_id)
  end

end # BranchDiaries
