class Bookmarks < Application
  # provides :xml, :yaml, :js

  def index
    @bookmarks = Bookmark.shared_for(session.user, params[:type])
    display @bookmarks, :layout => layout?
  end

  def show(id)
    @bookmark = Bookmark.get(id)
    raise NotFound unless @bookmark
    display @bookmark, :layout => layout?
  end

  def new
    only_provides :html
    @bookmark = Bookmark.new
    display @bookmark, :layout => layout?
  end

  def edit(id)
    only_provides :html
    @bookmark = Bookmark.get(id)
    raise NotFound unless @bookmark
    display @bookmark, :layout => layout?
  end

  def create(bookmark)
    @bookmark = Bookmark.new(bookmark)
    @bookmark.user =  session.user    
    if @bookmark.save
      notice = @bookmark.type==:other ? "Bookmark created" : "Report saved"
      request.xhr? ? render(notice, :layout => false) : redirect(resource(@bookmark), :message => {:notice => "Bookmark was successfully created"})
    else
      message[:error] = "Bookmark failed to be created"
      render :new, :layout => layout?
    end
  end

  def update(id, bookmark)
    @bookmark = Bookmark.get(id)
    raise NotFound unless @bookmark
    if @bookmark.update(bookmark)
      notice = @bookmark.type==:other ? "Bookmark created" : "Report saved"
      request.xhr? ? render(notice) : redirect(resource(:bookmarks, {:type => @bookmark.type}), :message => {:notice => "Bookmark was successfully created"})
    else
      display @bookmark, :edit
    end
  end

  def destroy(id)
    @bookmark = Bookmark.get(id)
    raise NotFound unless @bookmark
    if @bookmark.destroy
      redirect resource(:bookmarks)
    else
      raise InternalServerError
    end
  end

end # Bookmarks
