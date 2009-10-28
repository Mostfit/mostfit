require "log4r"
class Admin < Application
  include Log4r
  before :ensure_has_admin_privileges

  def index
    render
  end

  def upload    
    if params[:file]
      file      = Upload.new(params[:file][:filename])      
      log       = Logger.new 'upload_log'
      pf        = PatternFormatter.new(:pattern => "<b>[%l]</b> %m")
      file_log  = Log4r::FileOutputter.new('output_log', :filename => [Merb.root, "public", "logs", file.directory].join("/"), :truncate => false, :formatter => pf)
      log.add(file_log) 
      log.level = INFO

      file.move(params[:file][:tempfile].path)

      Merb.run_later do        
        log.info("File has been uploaded to the server. Now processing it into a bunch of csv files")
        file.process_excel_to_csv
        log.info("CSVs extraction complete. Processing files.")
        file.load_csv(log)
        log.info("<h2>Processing complete! Your MIS is now ready for use. Please take a note of all the errors reported here(if any) and rectify them.</h2>")        
      end
      redirect "/admin/upload_status/#{file.directory}"
    else
      render
    end
  end

  def upload_status        
    render
  end
  
end
