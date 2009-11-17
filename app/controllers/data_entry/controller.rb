module DataEntry
  # the controller class for the data entry side of the site...
  class Controller < Application
    before :ensure_has_data_entry_privileges    
    # this redirects all indexes by default to the 'dashboard'
    def index
      redirect url(:data_entry)
    end    
  end
end
