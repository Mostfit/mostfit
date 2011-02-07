module DataEntry
  class Index < Controller
    def index
      render
    end
    

    def fixate
      # Set branch id
      session[:branch_id] = ((params[:branch_id] and params[:branch_id].to_i>0 and branch = Branch.get(params[:branch_id])) ? params[:branch_id] : nil)
      
      # Set center id
      if params[:center_id] and params[:center_id].to_i>0 and center = Center.get(params[:center_id]) and branch.id == session[:branch_id].to_i
        session[:center_id] = params[:center_id]
      else
        session[:center_id] = nil
      end

      redirect url(:data_entry)
    end
    
  end

end
